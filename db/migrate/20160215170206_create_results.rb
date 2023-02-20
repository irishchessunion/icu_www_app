class CreateResults < ActiveRecord::Migration[7.0]
  def change
    create_table :results do |t|
      t.string :competition
      t.string :player1
      t.string :player2
      t.string :score
      t.references :reporter
      t.boolean :active

      t.timestamps null: false
    end
  end
end
