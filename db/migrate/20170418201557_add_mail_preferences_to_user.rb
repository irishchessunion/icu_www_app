class AddMailPreferencesToUser < ActiveRecord::Migration
  def change
    add_column :users, :junior_newsletter, :boolean
    add_column :users, :newsletter, :boolean
  end
end
