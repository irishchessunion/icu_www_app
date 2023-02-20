class CreateLogins < ActiveRecord::Migration[7.0]
  def change
    create_table :logins do |t|
      t.integer  :user_id
      t.string   :email, :error, :roles
      t.string   :ip, limit: 39
      t.datetime :created_at
    end
  end
end
