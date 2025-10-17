class Snipe < ApplicationRecord
  belongs_to :user

  validates :name_to_seek, presence: true
  validates :name_to_seek, uniqueness: { if: :to_bid? }
  validates :max_price, presence: true, numericality: { greater_than: 0 }
  validates :min_float, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  validates :max_float, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  validate :min_float_less_than_max_float

  private

  def min_float_less_than_max_float
    return unless min_float.present? && max_float.present?

    if min_float >= max_float
      errors.add(:min_float, "must be less than max float")
    end
  end
end
