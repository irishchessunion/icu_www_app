require 'rails_helper'

describe "WYSIWYG notes for events and clubs", js: true do
  include_context "features"

  def set_editor_html(html)
    expect(page).to have_css("#wysiwyg_editor_mount .ql-editor", wait: 5)
    page.execute_script("document.querySelector('#wysiwyg_editor_mount').__quill.root.innerHTML = #{html.to_json};")
  end

  it "an organiser edits an event's notes and links an event, but can't insert an image" do
    organiser = create(:user, roles: "organiser")
    event = create(:event, user: organiser, note: "Old **Markdown** note")
    login organiser
    visit edit_admin_event_path(event)

    expect(page).to have_css("#wysiwyg_editor_mount strong", text: "Markdown")
    set_editor_html("<p><strong>Bring a clock</strong></p>")

    within "#wysiwyg_toolbar_extra" do
      expect(page).to have_button("Link Event")
      expect(page).to_not have_button("Insert Image")
    end
    expect(page).to_not have_css("#image_ids_modal", visible: :all)
    find("#wysiwyg_toolbar_extra button", text: "Link Event").click
    within "#event_ids_modal" do
      fill_in I18n.t("event.name"), with: event.name + force_submit
      click_link event.name
    end
    expect(page).to have_no_css(".modal-backdrop")
    click_button save

    expect(page).to have_css(success, text: "updated")
    event.reload
    expect(event.markdown).to be false
    expect(event.note).to include("Bring a clock", "[EVT:#{event.id}:#{event.name}]")
    expect(page).to have_css("#description strong", text: "Bring a clock")
    expect(page).to have_css("#description a[href='/events/#{event.id}']", text: event.name)
  end

  it "a club secretary edits the club's notes with only the pickers they can use" do
    secretary = create(:user)
    club = create(:club, secretary_id: secretary.player_id, notes: "Plain old notes")
    login secretary
    visit edit_admin_club_path(club)

    within "#wysiwyg_toolbar_extra" do
      expect(page).to have_button("Link Article")
      expect(page).to_not have_button("Insert Image")
      expect(page).to_not have_button("Link Event")
    end

    set_editor_html("<p>Meets <em>upstairs</em></p>")
    click_button save

    expect(page).to have_css(success, text: "updated")
    expect(club.reload.notes).to eq "<p>Meets <em>upstairs</em></p>"
    expect(page).to have_css("td em", text: "upstairs")
  end
end
