class AddActiveToOfficers < ActiveRecord::Migration[7.0]
  def change
    add_column :officers, :active, :boolean, default: true
    add_column :officers, :redirects, :string
  end
end
