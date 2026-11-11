# The @icu.ie mail relays are no longer used. Admins enter each officer's email and phone instead.
class ReplaceRelaysWithOfficerContacts < ActiveRecord::Migration[8.1]
  def change
    add_column :officers, :email, :string
    add_column :officers, :phone, :string, limit: 30

    drop_table :relays, id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci" do |t|
      t.boolean  :enabled, default: true
      t.string   :from, limit: 50
      t.integer  :officer_id
      t.string   :provider_id, limit: 50
      t.string   :to
      t.timestamps precision: nil
    end
  end
end
