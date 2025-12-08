class AddIsFideRatedFlagToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :is_fide_rated, :boolean, default: false
  end
end
