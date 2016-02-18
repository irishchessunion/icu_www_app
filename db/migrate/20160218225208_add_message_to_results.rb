class AddMessageToResults < ActiveRecord::Migration
  def change
    add_column :results, :message, :string
  end
end
