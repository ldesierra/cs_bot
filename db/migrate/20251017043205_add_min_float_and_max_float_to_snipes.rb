class AddMinFloatAndMaxFloatToSnipes < ActiveRecord::Migration[7.2]
  def change
    add_column :snipes, :min_float, :float
    add_column :snipes, :max_float, :float
  end
end
