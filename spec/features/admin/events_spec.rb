require 'rails_helper'

describe Event do
  include_context "features"

  let(:contact_name)  { I18n.t("event.contact") }
  let(:event_email)   { I18n.t("event.email") }
  let(:end_date)      { I18n.t("event.end") }
  let(:flyer)         { I18n.t("event.flyer") }
  let(:location)      { I18n.t("event.location") }
  let(:event_name)    { I18n.t("event.name") }
  let(:phone)         { I18n.t("event.phone") }
  let(:prize_fund)    { I18n.t("event.prize_fund") }
  let(:start_date)    { I18n.t("event.start") }
  let(:url)           { I18n.t("event.url") }

  let(:doc)           { "kilkenny_2005.doc" }
  let(:docx)          { "bray_2014.docx" }
  let(:pdf)           { "ennis_2014.pdf" }
  let(:rtf)           { "galway_2005.rtf" }

  let(:event_dir)     { Rails.root + "spec/files/events/" }
  let(:image_dir)     { Rails.root + "spec/files/images/" }

  context "authorization" do
    let(:level1) { ["admin", user] }
    let(:level2) { ["editor"] }
    let(:level3) { User::ROLES.reject { |r| r.match(/\A(admin|editor|organiser)\z/) }.append("guest") }
    let(:user)   { create(:user, roles: "organiser") }
    let(:event)  { create(:event, user: user) }
    let(:header) { "h1" }

    it "level 1 can update as well as create" do
      level1.each do |role|
        login role
        visit new_admin_event_path
        expect(page).to_not have_css(failure)
        visit edit_admin_event_path(event)
        expect(page).to_not have_css(failure)
        visit events_path
        click_link event.name
        expect(page).to have_css(header, text: event.name)
        expect(page).to have_link(edit)
      end
    end

    it "level 2 can only create" do
      level2.each do |role|
        login role
        visit new_admin_event_path
        expect(page).to_not have_css(failure)
        visit edit_admin_event_path(event)
        expect(page).to have_css(failure)
        visit events_path
        click_link event.name
        expect(page).to have_css(header, text: event.name)
        expect(page).to_not have_link(edit)
      end
    end

    it "level 3 can only view" do
      level3.each do |role|
        login role
        visit new_admin_event_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_event_path(event)
        expect(page).to have_css(failure, text: unauthorized)
        visit events_path
        click_link event.name
        expect(page).to have_css(header, text: event.name)
        expect(page).to_not have_link(edit)
      end
    end
  end

  context "create" do
    let(:contact_text)  { "Gerry Graham" }
    let(:email_text)    { "gerrygraham@eircom.net" }
    let(:lat_text)      { "52.696169" }
    let(:long_text)     { "-8.815144" }
    let(:location_text) { "Bunratty, Limerick" }
    let(:name_text)     { "Bunratty Congress" }
    let(:note_text)     { "The best Irish tournament." }
    let(:start)         { Date.today.years_since(1) }
    let(:phone_text)    { "0872273593" }
    let(:fund_text)     { "3250" }
    let(:url_text)      { "http://www.bunrattychess.com/home/index.php" }
    let(:finish)        { start.days_since(2) }

    before(:each) do
      @user = login("organiser")
      visit new_admin_event_path
      fill_in end_date, with: finish.to_s
      fill_in location, with: location_text
      fill_in event_name, with: name_text
      fill_in start_date, with: start.to_s
    end

    it "minimum data" do
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.active).to be false
      expect(event.category).to eq Event::CATEGORIES[0]
      expect(event.contact).to be_nil
      expect(event.email).to be_nil
      expect(event.end_date).to eq finish
      expect(event.flyer).to be_blank
      expect(event.lat).to be_nil
      expect(event.location).to eq location_text
      expect(event.long).to be_nil
      expect(event.name).to eq name_text
      expect(event.note).to be_nil
      expect(event.phone).to be_nil
      expect(event.prize_fund).to be_nil
      expect(event.source).to eq "www2"
      expect(event.start_date).to eq start
      expect(event.url).to be_nil
      expect(event.user).to eq @user
    end

    it "maximum data" do
      check active
      select I18n.t("event.category.#{Event::CATEGORIES[1]}"), from: category
      fill_in contact_name, with: contact_text
      fill_in event_email, with: email_text
      fill_in latitude, with: lat_text
      fill_in longitude, with: long_text
      fill_in notes, with: note_text
      fill_in phone, with: phone_text
      fill_in prize_fund, with: fund_text
      fill_in url, with: url_text

      check I18n.t("event.is_fide_rated")
      ["classical", "rapid"].each do |control|
        label_text = I18n.t("event.time_controls.#{control}")
        check label_text
      end

      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.active).to be true
      expect(event.is_fide_rated).to be true
      expect(event.time_controls).to match_array(["classical", "rapid"])
      expect(event.category).to eq Event::CATEGORIES[1]
      expect(event.contact).to eq contact_text
      expect(event.email).to eq email_text
      expect(event.end_date).to eq finish
      expect(event.flyer).to be_blank
      expect(event.lat).to eq lat_text.to_f
      expect(event.location).to eq location_text
      expect(event.long).to eq long_text.to_f
      expect(event.name).to eq name_text
      expect(event.note).to eq note_text
      expect(event.phone).to eq phone_text
      expect(event.prize_fund).to eq fund_text.to_f
      expect(event.source).to eq "www2"
      expect(event.start_date).to eq start
      expect(event.url).to eq url_text
      expect(event.user).to eq @user
    end

    it "PDF" do
      attach_file flyer, event_dir + pdf
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq pdf
      expect(event.flyer_file_size).to eq 41571
      expect(event.flyer_content_type).to eq "application/pdf"
    end

    it "DOCX" do
      attach_file flyer, event_dir + docx
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq docx
      expect(event.flyer_file_size).to eq 14734
      expect(event.flyer_content_type).to eq "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    end

    it "DOC" do
      attach_file flyer, event_dir + doc
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq doc
      expect(event.flyer_file_size).to eq 48128
      expect(event.flyer_content_type).to eq "application/msword"
    end

    it "RTF" do
      attach_file flyer, event_dir + rtf
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Event.count).to eq 1
      event = Event.first

      expect(event.flyer_file_name).to eq rtf
      expect(event.flyer_file_size).to eq 6846
      expect(event.flyer_content_type).to match(/\A(application|text)\/rtf\z/)
    end

    it "invalid file type" do
      attach_file flyer, image_dir + "april.jpeg"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "invalid")
      expect(Event.count).to eq 0
    end

    it "file too big" do
      attach_file flyer, event_dir + "too_large.pdf"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "between")
      expect(Event.count).to eq 0
    end

    it "file too small" do
      attach_file flyer, event_dir + "too_small.rtf"
      click_button save

      expect(page).to_not have_css(success)
      expect(page).to have_css(field_error, text: "between")
      expect(Event.count).to eq 0
    end
  end

  context "index" do
    let(:organiser1) { create(:user, roles: "organiser") }
    let(:organiser2) { create(:user, roles: "organiser") }
    let(:admin_user) { create(:user, roles: "admin") }
    let(:regular_user) { create(:user, roles: "member") }

    let!(:upcoming_event1) do
      upcoming_event1 = build(:event, user: organiser1, name: "Dublin Congress", start_date: Date.today + 10, end_date: Date.today + 12, active: true)
      upcoming_event1.save!(validate: false)
      upcoming_event1
    end

    let!(:upcoming_event2) do
      upcoming_event2 = build(:event, user: organiser2, name: "Cork Open", start_date: Date.today + 15, end_date: Date.today + 17, active: false)
      upcoming_event2.save!(validate: false)
      upcoming_event2
    end

    let!(:past_event1) do
      past_event1 = build(:event, user: organiser1, name: "Belfast Classic", start_date: Date.today - 12, end_date: Date.today - 10, active: true)
      past_event1.save!(validate: false)
      past_event1
    end

    let!(:past_event2) do
      past_event2 = build(:event, user: organiser2, name: "Galway Rapid", start_date: Date.today - 17, end_date: Date.today - 15, active: false)
      past_event2.save!(validate: false)
      past_event2
    end

    context "authorization" do
      it "allows admin to access index" do
        login admin_user
        visit admin_events_path
        expect(page).to_not have_css(failure)
        expect(page).to have_content("Dublin Congress")
      end

      it "allows organiser to access index" do
        login organiser1
        visit admin_events_path
        expect(page).to_not have_css(failure)
        expect(page).to have_content("Dublin Congress")
      end

      it "denies regular users access" do
        login regular_user
        visit admin_events_path
        expect(page).to have_css(failure, text: unauthorized)
      end

      it "denies guests access" do
        visit admin_events_path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end

    context "organiser view" do
      before do
        login organiser1
        visit admin_events_path
      end

      it "shows only their own upcoming events" do
        expect(page).to have_content("Dublin Congress")
        expect(page).not_to have_content("Cork Open")
      end

      it "shows only their own past events" do
        expect(page).to have_content("Belfast Classic")
        expect(page).not_to have_content("Galway Rapid")
      end

      it "hides created by column" do
        expect(page).not_to have_content(I18n.t("event.created_by"))
      end

      it "hides user filter dropdown" do
        expect(page).not_to have_select(I18n.t("event.creator"))
      end
    end

    context "admin view" do
      before do
        login admin_user
        visit admin_events_path
      end

      it "shows all upcoming events" do
        expect(page).to have_content("Dublin Congress")
        expect(page).to have_content("Cork Open")
      end

      it "shows all past events" do
        expect(page).to have_content("Belfast Classic")
        expect(page).to have_content("Galway Rapid")
      end

      it "shows created by column" do
        expect(page).to have_content(I18n.t("event.created_by"))
      end

      it "shows user filter dropdown" do
        expect(page).to have_select(I18n.t("event.creator"))
      end

      it "filters by user" do
        select organiser1.name, from: I18n.t("event.creator")
        click_button I18n.t("search")

        expect(page).to have_content("Dublin Congress")
        expect(page).not_to have_content("Cork Open")
        expect(page).to have_content("Belfast Classic")
        expect(page).not_to have_content("Galway Rapid")
      end

      it "shows all users when 'All' is selected" do
        select organiser1.name, from: I18n.t("event.creator")
        click_button I18n.t("search")
        select I18n.t("all"), from: I18n.t("event.creator")
        click_button I18n.t("search")

        expect(page).to have_content("Dublin Congress")
        expect(page).to have_content("Cork Open")
      end
    end

    context "search" do
      it "filters by name for organiser" do
        login organiser1
        visit admin_events_path
        fill_in I18n.t("name"), with: "Dublin"
        click_button I18n.t("search")

        expect(page).to have_content("Dublin Congress")
        expect(page).not_to have_content("Belfast Classic")
      end

      it "filters by name for admin" do
        login admin_user
        visit admin_events_path
        fill_in I18n.t("name"), with: "Dublin"
        click_button I18n.t("search")

        expect(page).to have_content("Dublin Congress")
        expect(page).not_to have_content("Cork Open")
      end
    end

    context "empty state" do
      it "shows no events message when organiser has no events" do
        new_organiser = create(:user, roles: "organiser")
        login new_organiser
        visit admin_events_path

        expect(page).to have_content(I18n.t("event.upcoming"))
        expect(page).to have_content(I18n.t("event.past"))
        expect(page).not_to have_link("Dublin Congress")
      end
    end

    context "event display" do
      before do
        login organiser1
        visit admin_events_path
      end

      it "shows event names as links to manage" do
        expect(page).to have_link("Dublin Congress", href: admin_event_path(upcoming_event1))
      end

      it "shows active events with checkmark" do
        expect(page).to have_content("✔")
      end
    end
  end

  context "edit a event thats ended" do
    let(:user) { create(:user, roles: "organiser") }

    let(:ended_event) do
      ended_event = build(
        :event,
        user: user,
        name: "Bunratty Congress",
        location: "Bunratty, Limerick",
        start_date: Date.today.days_ago(14),
        end_date: Date.today.days_ago(7)
      )
      ended_event.save!(validate: false)
      ended_event
    end

    before do
      @user = login(user)
      visit edit_admin_event_path(ended_event)
    end

    it "displays that fields cannot be edited" do
      expect(page).to have_text(I18n.t("event.admin.cannot_edit_past_fields"))
    end

    it "disables name field" do
      expect(page).to have_field(event_name, disabled: true)
    end

    it "disables start and end date fields" do
      expect(page).to have_field(start_date, disabled: true)
      expect(page).to have_field(end_date, disabled: true)
    end

  end
end
