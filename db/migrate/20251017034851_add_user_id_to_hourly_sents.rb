class AddUserIdToHourlySents < ActiveRecord::Migration[7.2]
  def change
    add_reference :hourly_sents, :user, null: true, foreign_key: true
  end
end
