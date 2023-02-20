class RenameIcuId < ActiveRecord::Migration[7.0]
  change_table :users do |t|
    t.rename :icu_id, :player_id
  end
end
