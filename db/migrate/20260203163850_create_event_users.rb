class CreateEventUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :event_users do |t|
      t.references :event, null: false
      t.references :user, null: false
      t.string :role, null: false, default: "full_access"

      t.timestamps
    end

    add_index :event_users, [:event_id, :user_id], unique: true
  end
end
