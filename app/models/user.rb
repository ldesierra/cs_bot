class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Virtual attribute for admin password validation
  attr_accessor :admin_password

  has_one :portfolio, dependent: :destroy
  has_many :snipes, dependent: :destroy
  has_many :viewed_items, dependent: :destroy
  has_and_belongs_to_many :hourly_sents, join_table: :hourly_sent_users

  validates :user_number, presence: true
  validate :user_number_uniqueness
  validate :admin_password_validation

  def user_number_uniqueness
    return if user_number.blank?

    existing_user = User.where(user_number: user_number).where.not(id: id).first
    if existing_user
      errors.add(:user_number, 'has already been taken')
    end
  end

  def admin_password_validation
    return if admin_password.blank?

    if admin_password != ENV["ADMIN_PASSWORD"]
      errors.add(:admin_password, 'is incorrect')
    end
  end

  def total_profit
    return off_skin_balance unless portfolio&.transactions&.any?

    portfolio.transactions
             .where.not(sell: nil).pluck(:sell, :buy_price).sum { |sell, buy_price| sell - buy_price }
  end

  def mark_item_as_seen(item_id)
    # Ensure we have a proper array to work with
    current_ids = seen_item_ids || []
    new_ids = (current_ids + [item_id.to_s]).uniq

    # Use update_column to bypass validations and ensure direct database update
    update_column(:seen_item_ids, new_ids)

    # Reload to ensure the change is persisted
    reload
  end

  def has_seen_item?(item_id)
    # Ensure we have a proper array and handle nil cases
    (seen_item_ids || []).include?(item_id.to_s)
  end

  def clear_seen_items
    update_column(:seen_item_ids, [])
    reload
  end

  # Alternative methods using the viewed_items table (more reliable)
  def mark_item_as_seen_table(item_id)
    viewed_items.find_or_create_by(item_id: item_id.to_s)
  end

  def has_seen_item_table?(item_id)
    viewed_items.exists?(item_id: item_id.to_s)
  end

  def clear_seen_items_table
    viewed_items.destroy_all
  end

  # Hybrid approach - try table first, fallback to JSON column
  def mark_item_as_seen_hybrid(item_id)
    begin
      mark_item_as_seen_table(item_id)
    rescue => e
      Rails.logger.warn "Table approach failed, falling back to JSON: #{e.message}"
      mark_item_as_seen(item_id)
    end
  end

  def has_seen_item_hybrid?(item_id)
    has_seen_item_table?(item_id) || has_seen_item?(item_id)
  end
end
