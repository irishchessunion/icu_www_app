class AlterLogins < ActiveRecord::Migration[7.0]
  change_table :logins do |t|
    t.remove :email
    t.change :ip, :string, limit: 50
  end
end
