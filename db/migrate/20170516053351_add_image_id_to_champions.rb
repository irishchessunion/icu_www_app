class AddImageIdToChampions < ActiveRecord::Migration
  def change
    add_reference :champions, :image, foreign_key: true
  end
end
