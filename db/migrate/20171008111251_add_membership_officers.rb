class AddMembershipOfficers < ActiveRecord::Migration
  def up
    Officer.create!(role: "membership-connaught", rank: 25, executive: false)
    Officer.create!(role: "membership-leinster", rank: 26, executive: false)
    Officer.create!(role: "membership-munster", rank: 27, executive: false)
  end

  def down
    Officer.delete_all("role like 'membership-%'")
  end
end
