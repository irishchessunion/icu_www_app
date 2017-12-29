class AddUrlToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :url, :string
  end
end
