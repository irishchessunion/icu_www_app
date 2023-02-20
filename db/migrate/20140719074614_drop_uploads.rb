class DropUploads < ActiveRecord::Migration[7.0]
  def up
    drop_table :uploads
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
