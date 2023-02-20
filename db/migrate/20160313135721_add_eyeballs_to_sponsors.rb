class AddEyeballsToSponsors < ActiveRecord::Migration[7.0]
  def change
    add_column :sponsors, :eyeballs, :integer
    Sponsor.update_all(eyeballs: 0)
  end
end
