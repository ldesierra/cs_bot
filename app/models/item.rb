class Item < ApplicationRecord
  belongs_to :transaction_involved, class_name: 'Transaction', foreign_key: 'transaction_involved_id'

  validates :float, presence: true, numericality: { greater_than_or_equal_to: 0.00001, less_than_or_equal_to: 0.99999 }
  validates :fade, numericality: { greater_than_or_equal_to: 80.0, less_than_or_equal_to: 99.9 }, allow_nil: true
  validates :blue, numericality: { greater_than_or_equal_to: 80.0, less_than_or_equal_to: 99.9 }, allow_nil: true
end
