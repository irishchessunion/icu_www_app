class AddSectionsToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :sections, :string
    add_column :fees, :sections, :string
    add_column :items, :section, :string
  end
end
