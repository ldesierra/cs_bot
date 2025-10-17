class Bidded < ApplicationRecord
  belongs_to :item, foreign_key: 'item_id', primary_key: 'item_id'

  validates :bidded_by, presence: true, inclusion: { in: [0, 1, 2] }
  validates :item_id, presence: true
end
