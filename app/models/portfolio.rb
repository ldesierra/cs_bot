class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy
  has_many :items, through: :transactions, source: :item
  has_many :hourly_sents, through: :items
end
