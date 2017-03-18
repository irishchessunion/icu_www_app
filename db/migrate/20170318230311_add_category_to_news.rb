class AddCategoryToNews < ActiveRecord::Migration
  def change
    add_column :news, :category, :string, limit: 20
  end
end
