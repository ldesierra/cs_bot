class Transaction < ApplicationRecord
  belongs_to :portfolio
  has_one :item, class_name: 'Item', foreign_key: 'transaction_involved_id', dependent: :destroy

  accepts_nested_attributes_for :item
end
