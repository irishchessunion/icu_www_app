class AddMessageToResults < ActiveRecord::Migration[7.0]
  def change
    add_column :results, :message, :string
  end
end
