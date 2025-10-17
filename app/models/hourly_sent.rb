class HourlySent < ApplicationRecord
  belongs_to :item
  has_and_belongs_to_many :users, join_table: :hourly_sent_users
  validates :date, presence: true
end
