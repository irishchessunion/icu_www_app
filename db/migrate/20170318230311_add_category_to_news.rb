class AddCategoryToNews < ActiveRecord::Migration[7.0]
  def change
    add_column :news, :category, :string, limit: 20
  end
end
