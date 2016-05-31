require 'csv'

module Admin
  class EntryListCsvGenerator
    def generate_from_items(items, description = nil)
      CSV.generate do |csv|
        csv << ["Items for #{description} generated on #{Time.now}", '', '', '', '']
        csv << %w(Description Player ICU# Rating Fee Status Section Notes)
        items.each do |item|
          if item.player.present?
            name, id, rating = item.player.name, item.player.id, item.player.latest_rating
          elsif new_player = item.new_player
            name, id, rating = new_player.name, 'new', 'unknown'
          else
            name, id, rating = nil, nil, nil
          end
          csv << [item.description, name, id, rating, item.cost, item.status, item.section, *item.notes]
        end
      end
    end
  end
end