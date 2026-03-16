class CreateArbiters < ActiveRecord::Migration[7.0]
  def change
    create_table :arbiters do |t|
      t.integer :player_id, null: false
      t.string  :email
      t.string  :phone
      t.string  :location
      t.string  :level, null: false
      t.date    :date_of_qualification, null: false
      t.boolean :active, default: true, null: false
      t.boolean :available, default: true, null: false

      t.timestamps
    end

    add_index :arbiters, :player_id, unique: true
    add_index :arbiters, :level
    add_index :arbiters, :active
  end
end
