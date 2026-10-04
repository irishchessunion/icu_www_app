require 'csv'

module Admin
  class EntryListCsvGenerator
    # The paid date is for the treasurer's items CSV only, so the event entry downloads, which organisers
    # import into pairing software, keep their columns.
    def generate_from_items(items, description = nil, show_charge_id = false, show_paid_date: false)
      CSV.generate do |csv|
        csv << ["Items for #{description} generated on #{Time.now}", '', '', '', '']
        headings = ["Date"]
        headings << "Paid-Date" if show_paid_date
        if show_charge_id
          headings.concat(%w(Charge# Cart#))
        end
        headings.concat(%w(Description Player ICU# Rating Fee Status Event-Name Event-ID Section Email Cart-Email Notes))
        csv << headings
        items.each do |item|
          event = item.is_a?(Item::Entry) ? item.fee&.event : nil
          if item.player.present?
            name, id, rating, email = item.player.name, item.player.id, item.player.latest_rating, item.player.email
          elsif new_player = item.new_player
            name, id, rating, email = new_player.name, 'new', 'unknown', ''
          else
            name, id, rating, email = nil, nil, nil, ''
          end
          row = [item.created_at.strftime("%Y-%m-%d")]
          row << item.cart&.payment_completed&.strftime("%Y-%m-%d") if show_paid_date
          if show_charge_id
            latest_charge = item.cart.present? && item.cart.latest_charge.present? ? item.cart.latest_charge : "(was not stored pre-update)"
            latest_charge = "N/A" unless !item.cost.nil? and item.cost > 0
            row.concat([latest_charge, item.cart_id])
          end
          row.concat([item.description, name, id, rating, item.cost, item.status, event&.name, event&.id, item.section, email, item.email, *item.notes])
          csv << row
        end
      end
    end
  end
end
