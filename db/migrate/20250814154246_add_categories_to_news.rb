class AddCategoriesToNews < ActiveRecord::Migration[7.0]
  def up
    # flag_shih_tzu-managed bit field
    add_column :news, :categories, :integer, null: false, default: 0
    CategoriesOwner::CATEGORIES.each do |category|
      News.where(category: category).update_all(News.set_flag_sql(category.to_sym, true))
    end
    # I'd like to remove the category column, but I'll leave it be for the moment.
  end

  def down
    remove_column :news, :categories
  end
end
