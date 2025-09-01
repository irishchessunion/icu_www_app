class IncreaseLengthOfEventsNoteField < ActiveRecord::Migration[7.0]
  def up
    change_column :events, :note, :text
  end

  def down
    # Create a temporary column to hold the truncated values
    add_column :events, :temp_note, :string

    # Copy data, truncating if longer than 255 characters
    Event.find_each do |event|
      temp_note = event.note
      if event.note && event.note.length > 511
        temp_note = event.note[0, 511]
      end
      event.update_column(:temp_note, temp_note)
    end

    # Remove the original column and rename the temporary column
    remove_column :events, :note
    rename_column :events, :temp_note, :note
  end
end
