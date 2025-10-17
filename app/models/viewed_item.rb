class ViewedItem < ApplicationRecord
  belongs_to :user

  validates :item_id, presence: true
  validates :item_id, uniqueness: { scope: :user_id }
end
