require 'rails_helper'

describe Club do
  include_context "features"

  let(:county)        { I18n.t("club.county") }
  let(:district)      { I18n.t("club.district") }
  let(:meetings)      { I18n.t("club.meet") }
  let(:phone)         { I18n.t("club.phone") }
  let(:website)       { I18n.t("club.web") }

  context "authorization" do
    let(:club)   { create(:club) }
    let(:header) { "//h2[.='#{club.name}']" }
    let(:level1) { %w[admin editor] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    it "level 1 can manage clubs as well as view" do
      level1.each do |role|
        login role
        visit new_admin_club_path
        expect(page).to_not have_css(failure)
        visit edit_admin_club_path(club)
        expect(page).to_not have_css(failure)
        visit club_path(club)
        expect(page).to have_xpath(header)
        expect(page).to have_link(edit)
      end
    end

    it "level 2 can only view" do
      level2.each do |role|
        login role
        visit new_admin_club_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_club_path(club)
        expect(page).to have_css(failure, text: unauthorized)
        visit club_path(club)
        expect(page).to have_xpath(header)
        expect(page).to_not have_link(edit)
      end
    end

    it "shows the admin section to a club secretary for their own club" do
      secretary = create(:user)
      club.update!(secretary: secretary.player)
      other_club = create(:club, name: "Other Chess Club")

      login secretary
      visit club_path(club)

      expect(page).to have_css(".show-admin", text: "Secretary: #{secretary.player.name} (#{secretary.player.id})")
      click_link "Edit Club"
      expect(page).to have_current_path(edit_admin_club_path(club))

      visit club_path(other_club)
      expect(page).not_to have_css(".show-admin")
    end
  end

  context "create" do
    before(:each) do
      login "editor"
      visit clubs_path
      click_link new_one
    end

    it "successful creation with all attributes" do
      fill_in name, with: "Bangor"
      fill_in website, with: "www.ulsterchess.org/membership/Clubs/bangor"
      fill_in address, with: "The Pub"
      fill_in city, with: "Bangor"
      select "Down", from: county
      fill_in I18n.t("eircode"), with: "BT20 5ED"
      fill_in latitude, with: 54.67301
      fill_in longitude, with: -5.61431
      fill_in contact, with: "Eddie Webb"
      fill_in email, with: "eddie.webb@heaven.com"
      fill_in phone, with: "02891 1234 567"
      check active
      click_button save

      expect(page).to have_css(success, text: created)
      club = Club.last

      expect(club.name).to eq "Bangor"
      expect(club.web).to eq "http://www.ulsterchess.org/membership/Clubs/bangor"
      expect(club.meet).to be_nil
      expect(club.address).to eq "The Pub"
      expect(club.district).to be_nil
      expect(club.city).to eq "Bangor"
      expect(club.county).to eq "down"
      expect(club.eircode).to eq "BT20 5ED"
      expect(club.province).to eq "ulster"
      expect(club.lat).to be_within(0.00001).of(54.67301)
      expect(club.long).to be_within(0.00001).of(-5.61431)
      expect(club.contact).to eq "Eddie Webb"
      expect(club.email).to eq "eddie.webb@heaven.com"
      expect(club.phone).to eq "02891 1234 567"
      expect(club.active).to eq true
    end

    it "successful creation with minimal attributes" do
      expect(page).not_to have_css("input#club_meet")
      expect(page).not_to have_content("Legacy field can no longer be edited")

      fill_in name, with: "Millisle"
      fill_in city, with: "Millisle"
      select "Down", from: county
      uncheck active
      click_button save

      expect(page).to have_css(success, text: created)
      club = Club.last

      expect(club.name).to eq "Millisle"
      expect(club.web).to be_nil
      expect(club.meet).to be_nil
      expect(club.address).to be_nil
      expect(club.district).to be_nil
      expect(club.city).to eq "Millisle"
      expect(club.county).to eq "down"
      expect(club.province).to eq "ulster"
      expect(club.lat).to be_nil
      expect(club.long).to be_nil
      expect(club.contact).to be_nil
      expect(club.email).to be_nil
      expect(club.phone).to be_nil
      expect(club.active).to eq false
    end
  end

  context "edit" do
    before(:each) do
      @bangor = create(:club)
      login "editor"
      visit edit_admin_club_path(@bangor)
    end

    it "orders saved meetings by weekday and start time" do
      @bangor.club_meetings.create!(day_of_week: "tuesday", start_time: "19:30", notes: "Tuesday")
      @bangor.club_meetings.create!(day_of_week: "sunday", start_time: "18:00", notes: "Sunday")
      @bangor.club_meetings.create!(day_of_week: "monday", start_time: "20:00", notes: "Monday late")
      @bangor.club_meetings.create!(day_of_week: "monday", start_time: "17:00", notes: "Monday early")

      visit edit_admin_club_path(@bangor)

      expect(page.all(".club-meeting-fields input[name$='[notes]']").map(&:value)).to eq ["Monday early", "Monday late", "Tuesday", "Sunday"]
    end

    it "displays legacy meetings beneath structured meetings without allowing edits" do
      expect(page).to have_css("section[data-controller='club-meetings'] input#club_meet[disabled][value='#{@bangor.meet}']")
      expect(page).to have_css("section[data-controller='club-meetings'] label[for='club_meet']", count: 1)
    end

    it "name is mandatory" do
      fill_in name, with: ""
      click_button save
      expect(page).to have_css(field_error, text: "blank")
    end

    it "city is mandatory" do
      fill_in city, with: ""
      click_button save
      expect(page).to have_css(field_error, text: "blank")
    end

    it "county is mandatory" do
      select please, from: county
      click_button save
      expect(page).to have_css(field_error, text: "invalid")
    end

    it "secretary is saved and shown in the admin panel" do
      player = create(:player)
      fill_in I18n.t("club.secretary"), with: player.id
      click_button save

      expect(page).to have_css(success)
      expect(@bangor.reload.secretary_id).to eq player.id

      visit club_path(@bangor)
      expect(page).to have_css(".show-admin", text: "Secretary: #{player.name} (#{player.id})")
    end

    it "secretary must be an existing player" do
      fill_in I18n.t("club.secretary"), with: 999999
      click_button save
      expect(page).to have_css(field_error, text: "does not exist")
      expect(@bangor.reload.secretary_id).to be_nil
    end

    it "at least one contact method is mandadory for an active club" do
      fill_in website, with: ""
      fill_in email, with: ""
      fill_in phone, with: ""
      click_button save
      expect(page).to have_css(failure, text: "contact")
      uncheck active
      click_button save
      expect(page).to have_css(success)
    end
  end

  context "meetings form", js: true do
    before(:each) { login "editor" }

    it "shows a full-width remove button at the bottom on mobile" do
      club = create(:club)
      club.club_meetings.create!(day_of_week: "tuesday", start_time: "18:00")
      visit edit_admin_club_path(club)

      window = page.driver.browser.manage.window
      original_size = window.size
      window.resize_to(390, 800)

      within find(".club-meeting-fields") do
        expect(page).to have_no_css("button.hidden-xs", visible: true)
        expect(page).to have_css("button.visible-xs-block.btn-block", visible: true, text: "Remove meeting")
        find("button.visible-xs-block").click
      end
      expect(page).to have_no_css(".club-meeting-fields")
    ensure
      window.resize_to(original_size.width, original_size.height) if window && original_size
    end

    it "rejects a juniors-only meeting that does not welcome juniors" do
      club = create(:club)
      meeting = club.club_meetings.create!(day_of_week: "tuesday", start_time: "18:00", audience: "juniors_only")
      visit edit_admin_club_path(club)

      within find(".club-meeting-fields") do
        find("label", text: "Welcomes juniors").click
      end
      click_button save

      expect(page).to have_css(".club-meeting-fields .help-block", text: "must be enabled for juniors-only meetings")
      expect(meeting.reload.welcomes_juniors).to be true
    end

    it "shows used note characters for saved and new meetings" do
      club = create(:club)
      club.club_meetings.create!(day_of_week: "tuesday", start_time: "18:00", notes: "Short")
      visit edit_admin_club_path(club)

      within find(".club-meeting-fields") do
        expect(page).to have_css("[data-club-meetings-target='count']", text: "5/100")
        fill_in "Notes", with: "Hello!"
        expect(page).to have_css("[data-club-meetings-target='count']", text: "6/100")
      end

      click_button "Add meeting"
      within all(".club-meeting-fields").last do
        expect(page).to have_css("[data-club-meetings-target='count']", text: "0/100")
        fill_in "Notes", with: "Hi"
        expect(page).to have_css("[data-club-meetings-target='count']", text: "2/100")
      end
      within all(".club-meeting-fields").first do
        expect(page).to have_css("[data-club-meetings-target='count']", text: "6/100")
      end
    end

    it "adds multiple meetings and discards a new row before saving" do
      visit new_admin_club_path
      fill_in name, with: "New Chess Club"
      fill_in city, with: "Bangor"
      select "Down", from: county
      uncheck active

      click_button "Add meeting"
      within all(".club-meeting-fields").first do
        select "Tuesday", from: "Day"
        fill_in "Start time", with: "18:00"
        fill_in "Notes", with: "Junior coaching"
        find(".inline-radio label", text: "Juniors only").click
      end

      click_button "Add meeting"
      within all(".club-meeting-fields").last do
        select "Thursday", from: "Day"
        fill_in "Start time", with: "19:30"
        find("label", text: "Welcomes juniors").click
      end

      click_button "Add meeting"
      within all(".club-meeting-fields").last do
        find("button[aria-label='Remove meeting']").click
      end
      expect(page).to have_css(".club-meeting-fields", count: 2)

      click_button save

      expect(page).to have_css(success, text: created)
      saved = Club.find_by!(name: "New Chess Club").club_meetings.order(:day_of_week).to_a
      expect(saved.map(&:day_of_week)).to eq %w[thursday tuesday]
      expect(saved.find { |meeting| meeting.day_of_week == "tuesday" }.notes).to eq "Junior coaching"
      expect(saved.find { |meeting| meeting.day_of_week == "thursday" }.welcomes_juniors).to be false
    end

    it "removes a saved meeting while retaining the others" do
      club = create(:club)
      removed = club.club_meetings.create!(day_of_week: "tuesday", start_time: "18:00")
      retained = club.club_meetings.create!(day_of_week: "thursday", start_time: "19:30")
      visit edit_admin_club_path(club)

      within all(".club-meeting-fields").first do
        find("button[aria-label='Remove meeting']").click
      end
      expect(page).to have_css(".club-meeting-fields", count: 1)
      within find(".club-meeting-fields") do
        fill_in "Notes", with: "All levels welcome"
        find(".inline-radio label", text: "Women only").click
      end
      click_button save

      expect(page).to have_css(success, text: updated)
      expect(club.reload.club_meetings.ids).to eq [retained.id]
      expect(retained.reload.notes).to eq "All levels welcome"
      expect(retained.audience).to eq "women_only"
      expect(ClubMeeting.exists?(removed.id)).to be false
    end
  end
end
