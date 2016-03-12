class CreateSponsors < ActiveRecord::Migration
  def up
    create_table :sponsors do |t|
      t.string :name
      t.integer :weight
      t.string :weblink
      t.string :contact_email
      t.string :contact_name
      t.string :contact_phone
      t.integer :clicks
      t.date :valid_until
      t.text :notes

      t.timestamps null: false
    end
    add_attachment :sponsors, :logo
  end

  def down
    remove_attachment :sponsors, :logo
    drop_table :sponsors
  end
end
