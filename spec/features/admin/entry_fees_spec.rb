require 'spec_helper'

feature "Authorization for entry fees" do
  given(:ok_roles)        { %w[admin treasurer] }
  given(:not_ok_roles)    { User::ROLES.reject { |role| ok_roles.include?(role) } }
  given(:fee)             { create(:entry_fee) }
  given(:success)         { "div.alert-success" }
  given(:failure)         { "div.alert-danger" }
  given(:button)          { I18n.t("edit") }
  given(:unauthorized)    { I18n.t("errors.messages.unauthorized") }
  given(:signed_in_as)    { I18n.t("session.signed_in_as") }
  given(:paths)           { [new_admin_entry_fee_path, edit_admin_entry_fee_path(fee), admin_entry_fees_path, admin_entry_fee_path(fee)] }

  scenario "the admin and treasurer roles can manage entry fees" do
    ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to_not have_css(failure)
      end
    end
  end

  scenario "other roles hae no access" do
    not_ok_roles.each do |role|
      login role
      expect(page).to have_css(success, text: signed_in_as)
      paths.each do |path|
        visit path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  scenario "guests have no access" do
    logout
    paths.each do |path|
      visit path
      expect(page).to have_css(failure, text: unauthorized)
    end
  end
end

feature "Create and delete an entry fee" do
  before(:each) do
    login("treasurer")
  end

  given(:success)           { "div.alert-success" }
  given(:failure)           { "div.help-block" }
  given(:amount)            { I18n.t("fee.amount") }
  given(:discounted_amount) { I18n.t("fee.discounted_amount") }
  given(:discount_deadline) { I18n.t("fee.discount_deadline") }
  given(:event_name)        { I18n.t("fee.entry.event_name") }
  given(:event_start)       { I18n.t("fee.entry.event_start") }
  given(:event_end)         { I18n.t("fee.entry.event_end") }
  given(:sale_start)        { I18n.t("fee.sale_start") }
  given(:sale_end)          { I18n.t("fee.sale_end") }
  given(:delete)            { I18n.t("delete") }
  given(:save)              { I18n.t("save") }

  scenario "no discount" do
    visit new_admin_entry_fee_path
    fill_in event_name, with: "Bunratty Masters"
    fill_in amount, with: "50"
    fill_in event_start, with: "2014-02-07"
    fill_in event_end, with: "2014-02-09"
    fill_in sale_start, with: "2013-10-01"
    fill_in sale_end, with: "2014-02-06"
    click_button save

    expect(page).to have_css(success, text: "created")

    fee = EntryFee.limit(1).first
    expect(fee.event_name).to eq "Bunratty Masters"
    expect(fee.amount).to eq 50.0
    expect(fee.discounted_amount).to be_nil
    expect(fee.discount_deadline).to be_nil
    expect(fee.event_start.to_s).to eq "2014-02-07"
    expect(fee.event_end.to_s).to eq "2014-02-09"
    expect(fee.sale_start.to_s).to eq "2013-10-01"
    expect(fee.sale_end.to_s).to eq "2014-02-06"
    expect(fee.year_or_season).to eq "2014"
    expect(fee.journal_entries.count).to eq 1
    expect(JournalEntry.count).to eq 1

    click_link delete
    expect(SubscriptionFee.count).to eq 0
    expect(JournalEntry.count).to eq 2
  end

  scenario "with discount" do
    visit new_admin_entry_fee_path
    fill_in event_name, with: "Bangor Xmas Special"
    fill_in amount, with: "35"
    fill_in discounted_amount, with: "30"
    fill_in discount_deadline, with: "2014-12-20"
    fill_in event_start, with: "2014-12-28"
    fill_in event_end, with: "2015-01-05"
    fill_in sale_start, with: "2014-10-01"
    fill_in sale_end, with: "2014-12-27"
    click_button save

    expect(page).to have_css(success, text: "created")

    fee = EntryFee.limit(1).first
    expect(fee.event_name).to eq "Bangor Xmas Special"
    expect(fee.amount).to eq 35.0
    expect(fee.discounted_amount).to eq 30
    expect(fee.discount_deadline.to_s).to eq "2014-12-20"
    expect(fee.event_start.to_s).to eq "2014-12-28"
    expect(fee.event_end.to_s).to eq "2015-01-05"
    expect(fee.sale_start.to_s).to eq "2014-10-01"
    expect(fee.sale_end.to_s).to eq "2014-12-27"
    expect(fee.year_or_season).to eq "2014-15"
    expect(fee.journal_entries.count).to eq 1
    expect(JournalEntry.count).to eq 1

    click_link delete
    expect(SubscriptionFee.count).to eq 0
    expect(JournalEntry.count).to eq 2
  end
  
  scenario "duplicate" do
    fee = create(:entry_fee)
    
    visit new_admin_entry_fee_path
    fill_in event_name, with: fee.event_name
    fill_in amount, with: fee.amount.to_s
    fill_in event_start, with: fee.event_start.to_s
    fill_in event_end, with: fee.event_end.to_s
    fill_in sale_start, with: fee.sale_start.to_s
    fill_in sale_end, with: fee.sale_end.to_s
    click_button save

    expect(page).to have_css(failure, text: "one per year/season")

    fill_in event_start, with: fee.event_start.years_since(1).to_s
    fill_in event_end, with: fee.event_end.years_since(1).to_s
    fill_in sale_start, with: fee.sale_start.years_since(1).to_s
    fill_in sale_end, with: fee.sale_end.years_since(1).to_s
    click_button save

    expect(page).to have_css(success, text: "created")
  end
end

feature "Edit an entry fee" do
  before(:each) do
    login("treasurer")
  end

  given(:fee)         { create(:entry_fee) }
  given(:amount)      { I18n.t("fee.amount") }
  given(:rollover)    { I18n.t("fee.rollover") }
  given(:edit)        { I18n.t("edit") }
  given(:save)        { I18n.t("save") }
  given(:success)     { "div.alert-success" }
  given(:description) { "//th[.='#{I18n.t("fee.description")}']/following-sibling::td" }

  scenario "update amount" do
    visit admin_entry_fee_path(fee)
    click_link edit
    fill_in amount, with: "99"
    click_button save

    fee = EntryFee.limit(1).first
    expect(fee.amount).to eq 99.0
  end

  scenario "rollover" do
    expect(JournalEntry.count).to eq 0
    
    expect(fee.rolloverable?).to be_true
    
    visit admin_entry_fee_path(fee)
    click_link rollover

    expect(page).to have_css(success, text: "rolled over")
    expect(page).to have_xpath(description, text: "#{fee.event_name} #{fee.year_or_season.to_i + 1}")
    expect(page).to_not have_link(rollover)

    expect(JournalEntry.where(action: "create").count).to eq 1
  end
end