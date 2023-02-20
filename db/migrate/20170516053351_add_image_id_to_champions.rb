class AddImageIdToChampions < ActiveRecord::Migration[7.0]
  def change
    add_reference :champions, :image, foreign_key: true
  end
end
