class AddOrganizerOnlyToFees < ActiveRecord::Migration[7.0]
  def change
    add_column :fees, :organizer_only, :boolean
  end
end
