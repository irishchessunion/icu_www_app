require 'rails_helper'

describe "Renew membership reminder" do
  include_context "features"
  include ActiveSupport::Testing::TimeHelpers

  let(:renew) { I18n.t("shop.renew") }

  it "shown on the home page in the grace period, but not after they renew" do
    travel_to(Date.new(2026, 11, 16)) do
      user = login(create(:user, expires_on: Date.new(2026, 12, 31)))
      visit home_path
      expect(page).to have_content("paid up member last season (2025-26). Your membership will expire on 31st December.")
      click_link renew
      expect(page).to have_current_path(shop_path)

      user.update_column(:expires_on, Date.new(2027, 12, 31))
      visit home_path
      expect(page).to_not have_link(renew)
    end
  end
end
