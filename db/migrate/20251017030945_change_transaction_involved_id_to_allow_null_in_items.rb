class ChangeTransactionInvolvedIdToAllowNullInItems < ActiveRecord::Migration[7.2]
  def change
    change_column_null :items, :transaction_involved_id, true
  end
end
