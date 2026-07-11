class AddSecretaryIdToClubs < ActiveRecord::Migration[8.0]
  def change
    add_column :clubs, :secretary_id, :integer
    add_index :clubs, :secretary_id
  end
end