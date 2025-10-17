class AddDescriptionToHourlySents < ActiveRecord::Migration[7.2]
  def change
    add_column :hourly_sents, :description, :text
  end
end
