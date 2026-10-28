require 'rails_helper'

describe JournalEntry do
  include_context "features"

  def create_club
    visit clubs_path
    click_link I18n.t("club.directory.new"), exact: true
    fill_in "Name", with: "Wandering Dragons"
    fill_in "City", with: "Bangor"
    select "Down", from: "County"
    fill_in "Email", with: "mark@markorr.net"
    click_button "Save"
    expect(page).to have_css(success)
    [Club.find_by(name: "Wandering Dragons"), JournalEntry.find_by(journalable_type: "Club", action: "create")]
  end

  def edit_user
    user = create(:user)
    visit admin_user_path(user)
    click_link "Edit"
    fill_in "Status", with: "banned"
    click_button "Save"
    [User.find_by(status: "banned"), JournalEntry.find_by(journalable_type: "User", action: "update", to: "banned")]
  end

  def xpath(id, *tds)
    xpath = %Q{//table[@id="#{id}"]/tbody/tr}
    if tds.any?
      xpath += %Q{/td[starts-with(.,"#{tds.shift.to_s[0,10]}")]}
      tds.each do |text|
        xpath += %Q{/following-sibling::td[starts-with(.,"#{text.to_s[0,10]}")]}
      end
    end
    xpath
  end

  before(:each) do
    @admin = login "admin"
    @name = @admin.signature[0,10]
    @ip = "127.0.0.1"
    @club, @club_creation = create_club
    @user, @user_change = edit_user
  end

  it "admin view" do
    login "admin"

    visit club_path(@club)
    expect(page).to have_css("h4", text: "Changes")
    expect(page).to have_xpath(xpath("changes"), count: 1)
    expect(page).to have_xpath(xpath("changes", "create", @name), count: 1)

    visit admin_user_path(@user)
    expect(page).to have_css("h4", text: "Changes")
    expect(page).to have_xpath(xpath("changes"), count: 2)
    expect(page).to have_xpath(xpath("changes", "update", "status", "banned", @name), count: 1)

    visit admin_journal_entries_path
    expect(page).to have_xpath(xpath("results"), count: 3)
    expect(page).to have_xpath(xpath("results", "Club", @club.id, "create", @name, @ip), count: 1)
    expect(page).to have_xpath(xpath("results", "User", @user.id, "update", "status", "banned", @name, @ip), count: 1)
  end

  it "editor view" do
    login "editor"

    visit club_path(@club)
    expect(page).to_not have_css("h4", text: "Changes")
    expect(page).to_not have_xpath(xpath("changes"))

    visit admin_journal_entries_path
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@club_creation)
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@user_change)
    expect(page).to have_css(failure, text: unauthorized)
  end

  it "treasurer view" do
    login "treasurer"

    visit club_path(@club)
    expect(page).to_not have_css("h4", text: "Changes")
    expect(page).to_not have_xpath(xpath("changes"))

    visit admin_journal_entries_path
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@club_creation)
    expect(page).to have_css(failure, text: unauthorized)

    visit admin_journal_entry_path(@user_change)
    expect(page).to have_css(failure, text: unauthorized)
  end

  it "delete parent object" do
    expect(JournalEntry.where(journalable_type: "User").count).to eq 2

    login "admin"
    visit admin_user_path(@user)
    click_link "Delete"

    expect(JournalEntry.where(journalable_type: "User").count).to eq 3
  end
end
