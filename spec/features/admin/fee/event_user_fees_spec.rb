require 'rails_helper'

describe "Fees for full-access event users" do
  include_context "features"

  let(:amount)    { I18n.t("fee.amount") }
  let(:fee_name)  { I18n.t("fee.name") }

  let(:creator)   { create(:user, roles: "organiser") }
  let(:full_user) { create(:user, roles: "organiser") }
  let(:event)     { create(:event, user: creator) }
  let!(:fee)      { create(:entry_fee, name: "Ennis Open", event: event) }

  before(:each) do
    create(:event_user, event: event, user: full_user, role: "full_access")
    login full_user
  end

  it "can edit a fee the creator added" do
    visit admin_event_path(event)
    click_link "Edit", href: edit_admin_fee_path(fee)
    fill_in fee_name, with: "Ennis Major"
    click_button save

    expect(page).to have_css(success, text: "updated")
    expect(fee.reload.name).to eq "Ennis Major"
  end

  it "can add a fee to the event" do
    visit new_admin_fee_path(type: "Fee::Entry", event_id: event.id)
    fill_in fee_name, with: "Ennis Minor"
    fill_in amount, with: "40"
    click_button save

    expect(page).to have_css(success, text: "created")
    expect(event.fee_entries.pluck(:name)).to contain_exactly("Ennis Open", "Ennis Minor")
  end

  it "can't add a fee to an event they don't have access to" do
    other_event = create(:event, user: creator)
    visit new_admin_fee_path(type: "Fee::Entry", event_id: other_event.id)
    fill_in fee_name, with: "Sneaky"
    fill_in amount, with: "1"
    click_button save

    expect(page).to have_css(failure, text: unauthorized)
    expect(other_event.fee_entries).to be_empty
  end

  it "can't delete a fee" do
    visit admin_fee_path(fee, show_delete_button_for_test: true)
    expect(page).to_not have_link(delete)
  end
end
