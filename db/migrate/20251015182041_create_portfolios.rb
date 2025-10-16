class CreatePortfolios < ActiveRecord::Migration[7.2]
  def change
    create_table :portfolios do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
