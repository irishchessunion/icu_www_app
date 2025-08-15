class AddCategoriesToArticles < ActiveRecord::Migration[7.0]
  def up
    # flag_shih_tzu-managed bit field
    add_column :articles, :categories, :integer, null: false, default: 0
    Article::CATEGORIES.each do |category|
      Article.where(category: category).update_all(Article.set_flag_sql(category.to_sym, true))
    end
    # I'd like to remove the category column, but I'll leave it be for the moment.
  end

  def down
    remove_column :articles, :categories
  end
end
