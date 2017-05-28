class AddOrganizerOnlyToFees < ActiveRecord::Migration
  def change
    add_column :fees, :organizer_only, :boolean
  end
end
