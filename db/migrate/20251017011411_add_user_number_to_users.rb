class AddUserNumberToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :user_number, :string
    add_index :users, :user_number, unique: true
  end
end
