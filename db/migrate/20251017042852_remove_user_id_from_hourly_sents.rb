class RemoveUserIdFromHourlySents < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :hourly_sents, :users
    remove_index :hourly_sents, :user_id
    remove_column :hourly_sents, :user_id, :bigint
  end
end
