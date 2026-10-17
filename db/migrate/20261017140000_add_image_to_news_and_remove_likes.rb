class AddImageToNewsAndRemoveLikes < ActiveRecord::Migration[8.1]
  def change
    add_reference :news, :image, type: :integer, index: true

    remove_column :news, :nlikes, :integer
    remove_column :articles, :nlikes, :integer

    drop_table :news_likes, id: :integer do |t|
      t.datetime :created_at, precision: nil
      t.integer :news_id
      t.integer :user_id
      t.index [:news_id, :user_id], unique: true
    end

    drop_table :article_likes, id: :integer do |t|
      t.integer :article_id
      t.datetime :created_at, precision: nil
      t.integer :user_id
      t.index [:article_id, :user_id], unique: true
    end
  end
end
