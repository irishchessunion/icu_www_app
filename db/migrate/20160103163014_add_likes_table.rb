class AddLikesTable < ActiveRecord::Migration
  def change
    create_table :article_likes do |t|
      t.references :article
      t.references :user
      t.timestamp :created_at
    end
    add_index :article_likes, [:article_id, :user_id], unique: true

    create_table :news_likes do |t|
      t.references :news
      t.references :user
      t.timestamp :created_at
    end
    add_index :news_likes, [:news_id, :user_id], unique: true

    add_column :articles, :nlikes, :integer
    add_column :news, :nlikes, :integer
  end
end
