class CreateClubMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :club_meetings do |t|
      t.references :club, type: :integer, null: false
      t.string :day_of_week, null: false
      t.time :start_time, null: false
      t.string :title
      t.text :notes
      t.string :audience, null: false, default: "open"
      t.boolean :welcomes_juniors, null: false, default: true

      t.timestamps
    end

    add_index :club_meetings, [:day_of_week, :club_id]
  end
end
