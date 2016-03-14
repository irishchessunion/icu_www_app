class AddEyeballsToSponsors < ActiveRecord::Migration
  def change
    add_column :sponsors, :eyeballs, :integer
    Sponsor.update_all(eyeballs: 0)
  end
end
