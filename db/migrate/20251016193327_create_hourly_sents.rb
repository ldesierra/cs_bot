class CreateHourlySents < ActiveRecord::Migration[7.2]
  def change
    create_table :hourly_sents do |t|
      t.references :item, null: false, foreign_key: true
      t.date :date

      t.timestamps
    end
  end
end
