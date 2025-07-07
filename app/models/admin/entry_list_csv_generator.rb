require 'csv'

module Admin
  class EntryListCsvGenerator
    def generate_from_items(items, description = nil)
      CSV.generate do |csv|
        csv << ["Items for #{description} generated on #{Time.now}", '', '', '', '']
        csv << %w(Date Charge# Description Player ICU# Rating Fee Status Section Email Cart# Cart-Email Notes)
        items.each do |item|
          if item.player.present?
            name, id, rating, email = item.player.name, item.player.id, item.player.latest_rating, item.player.email
          elsif new_player = item.new_player
            name, id, rating, email = new_player.name, 'new', 'unknown', ''
          else
            name, id, rating, email = nil, nil, nil, ''
          end
          latest_charge = item.cart.present? && item.cart.latest_charge.present? ? item.cart.latest_charge : "(was not stored pre-update)"
          latest_charge = "N/A" unless item.cost > 0
          csv << [item.created_at.strftime("%Y-%m-%d"), latest_charge, item.description, name, id, rating, item.cost, item.status, item.section, email, item.cart_id, item.email, *item.notes]
        end
      end
    end
  end
end