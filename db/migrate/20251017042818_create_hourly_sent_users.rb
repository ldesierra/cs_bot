class CreateHourlySentUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :hourly_sent_users do |t|
      t.references :hourly_sent, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :viewed_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :hourly_sent_users, [:hourly_sent_id, :user_id], unique: true
  end
end
