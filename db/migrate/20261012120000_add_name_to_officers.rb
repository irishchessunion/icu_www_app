# Officers used to be limited to a hard-coded list of roles, whose display names lived in the locale file.
# The name is now stored on the officer so that admins can create new positions without a code change.
# The role column is kept only as an internal key for the original officers (e.g. "women").
class AddNameToOfficers < ActiveRecord::Migration[8.1]
  NAMES = {
    "arbitration"          => "Arbitration Officer",
    "chairperson"          => "Chairperson",
    "connaught"            => "Connaught Delegate",
    "development"          => "Development Officer",
    "ecu"                  => "ECU Delegate",
    "fide"                 => "FIDE Delegate",
    "fide_ecu"             => "FIDE & ECU Delegate",
    "gameskeeper"          => "Gameskeeper",
    "juniors"              => "Junior Officer",
    "leinster"             => "Leinster Delegate",
    "membership"           => "Membership Officer",
    "membership-connaught" => "Connaught Membership Officer",
    "membership-leinster"  => "Leinster Membership Officer",
    "membership-munster"   => "Munster Membership Officer",
    "munster"              => "Munster Delegate",
    "president"            => "President",
    "publicrelations"      => "Public Relations Officer",
    "ratings"              => "Rating Officer",
    "secretary"            => "Secretary",
    "selections"           => "Selection Committee Chairperson",
    "tournaments"          => "Tournament Officer",
    "treasurer"            => "Treasurer",
    "ulster"               => "Ulster Delegate",
    "vicechairperson"      => "Vice Chairperson",
    "webmaster"            => "Webmaster",
    "women"                => "Women's Officer",
  }

  def up
    add_column :officers, :name, :string, limit: 50

    NAMES.each do |role, name|
      execute "UPDATE officers SET name = #{quote(name)} WHERE role = #{quote(role)}"
    end
    execute "UPDATE officers SET name = COALESCE(role, CONCAT('Officer ', id)) WHERE name IS NULL"

    change_column_null :officers, :name, false
  end

  def down
    remove_column :officers, :name
  end
end
