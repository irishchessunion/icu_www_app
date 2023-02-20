class RemoveRelaysFromOfficers < ActiveRecord::Migration[7.0]
  def change
    remove_column :officers, :emails, :string
    remove_column :officers, :redirects, :string
  end
end
