require 'rails_helper'

describe "Event entries chart", type: :feature, js: true do
  it "does not show an empty-period message for free entries when viewing gross revenue" do
    event = create(:event, subscription_required: false)
    fee = create(:entry_fee, event: event, amount: 0)
    cart = create(:cart, status: "paid", payment_completed: Time.current)
    create(:paid_entry_item, fee: fee, cart: cart, cost: 0)
    login "admin"
    visit admin_event_path(event)

    within "#event-entries" do
      expect(page).to have_css(".apexcharts-canvas")
      choose "Gross", allow_label_click: true
      expect(page).to have_css(".apexcharts-yaxis-title", text: "Gross (EUR)")
      expect(page).not_to have_content("No data for this period.")
      expect(page).not_to have_content("Unable to load chart")
    end
  end
end
