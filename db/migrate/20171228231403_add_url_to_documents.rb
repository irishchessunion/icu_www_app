class AddUrlToDocuments < ActiveRecord::Migration[7.0]
  def change
    add_column :documents, :url, :string
  end
end
