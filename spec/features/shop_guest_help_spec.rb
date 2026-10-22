require 'rails_helper'

describe "Shop help" do
  include_context "features"

  let(:title) { I18n.t("shop.guest_help.title") }
  let!(:fee)  { create(:subscription_fee) }

  it "is shown to guests, not signed in users, and explains Select Member" do
    visit shop_path
    expect(page).to have_css(".panel-title", text: title)
    expect(page).to have_link(I18n.t("shop.guest_help.sign_in"), href: sign_in_path)
    expect(page).to have_link(href: help_membership_path)

    click_link fee.description
    expect(page).to have_content("Has this person been an ICU member before?")

    login "member"
    visit shop_path
    expect(page).to_not have_css(".panel-title", text: title)
  end
end
