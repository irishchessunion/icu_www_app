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
    expect(page).to have_current_path(admin_event_path(event))
    event.reload
    expect(event.markdown).to be false
    expect(event.note).to include("Bring a clock", "[EVT:#{event.id}:#{event.name}]")

    click_link "Back to event"
    expect(page).to have_current_path(event_path(event))
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
    expect(page).to have_css("#description em", text: "upstairs")
  end

  it "preserves the editor's existing non-list HTML when club notes are saved" do
    club = create(:club, markdown: false, notes: <<~HTML.squish)
      <h3>Existing notes</h3>
      <p>Meet&nbsp;upstairs at <strong>7:30</strong> &amp; bring <em>a clock</em>.</p>
      <p><br></p><p><br></p>
      <blockquote>Visitors welcome</blockquote>
      <p><u>Contact</u> <a href="https://example.org/?a=1&amp;b=2">the club</a>.</p>
    HTML
    login "editor"
    visit edit_admin_club_path(club)

    expect(page).to have_css("#wysiwyg_editor_mount .ql-editor")
    editor_html = page.evaluate_script("document.querySelector('#wysiwyg_editor_mount').__quill.root.innerHTML")
    expected = club.sanitize_editor_html(editor_html)
    click_button save

    expect(page).to have_css(success, text: "updated")
    expect(club.reload.notes).to eq expected
  end

  it "preserves bullet and numbered lists when club notes are saved and reopened" do
    club = create(:club)
    login "editor"
    visit edit_admin_club_path(club)

    expect(page).to have_css("#wysiwyg_editor_mount .ql-editor")
    page.execute_script(<<~'JS')
      document.querySelector('#wysiwyg_editor_mount').__quill.setContents([
        { insert: "Club notes\n" },
        { insert: "Junior training" },
        { insert: "\n", attributes: { list: "bullet" } },
        { insert: "Bring a board" },
        { insert: "\n", attributes: { list: "bullet" } },
        { insert: "First round" },
        { insert: "\n", attributes: { list: "ordered" } },
        { insert: "Second round" },
        { insert: "\n", attributes: { list: "ordered" } },
        { insert: "Bring a clock" },
        { insert: "\n", attributes: { list: "bullet" } }
      ]);
    JS
    expect(page).to have_css(".ql-editor ul > li[data-list='bullet']", count: 3)
    expect(page).to have_css(".ql-editor ol > li[data-list='ordered']", count: 2)
    click_button save

    expect(page).to have_css(success, text: "updated")
    notes = club.reload.notes
    saved = Nokogiri::HTML.fragment(notes)
    expect(saved.at_css("p").text).to eq "Club notes"
    expect(saved.children.map(&:name)).to eq %w[p ul ol ul]
    expect(saved.css("ul > li").map(&:text)).to eq ["Junior training", "Bring a board", "Bring a clock"]
    expect(saved.css("ol > li").map(&:text)).to eq ["First round", "Second round"]
    expect(page).to have_css("#description ul > li", count: 3)
    expect(page).to have_css("#description ol > li", count: 2)

    visit edit_admin_club_path(club)
    expect(page).to have_css(".ql-editor ul > li[data-list='bullet']", count: 3)
    expect(page).to have_css(".ql-editor ol > li[data-list='ordered']", count: 2)
    click_button save

    expect(page).to have_css(success, text: "updated")
    expect(club.reload.notes).to eq notes
  end

  it "switches a middle item between bullet, numbered, and plain text using the toolbar" do
    club = create(:club, markdown: false, notes: "<ul><li>First</li><li>Middle</li><li>Last</li></ul>")
    login "editor"
    visit edit_admin_club_path(club)

    expect(page).to have_css(".ql-editor ul > li", count: 3)
    page.execute_script("window.wysiwygEditor.setSelection(6, 0);")
    find(".ql-toolbar button.ql-list[value='ordered']").click
    expect(page).to have_css(".ql-editor ul > li", count: 2)
    expect(page).to have_css(".ql-editor ol > li", text: "Middle", count: 1)

    find(".ql-toolbar button.ql-list[value='bullet']").click
    expect(page).to have_css(".ql-editor ul", count: 1)
    expect(page).to have_css(".ql-editor ul > li", count: 3)
    expect(page).to have_no_css(".ql-editor ol")

    find(".ql-toolbar button.ql-list[value='bullet']").click
    expect(page).to have_css(".ql-editor ul > li", count: 2)
    expect(page).to have_css(".ql-editor p", text: "Middle")
    click_button save

    expect(page).to have_css(success, text: "updated")
    expect(club.reload.notes).to eq "<ul><li>First</li></ul><p>Middle</p><ul><li>Last</li></ul>"
  end

  it "continues a bullet list on Enter and leaves it on an empty line" do
    club = create(:club)
    login "editor"
    visit edit_admin_club_path(club)

    expect(page).to have_css(".ql-editor")
    page.execute_script("window.wysiwygEditor.setText(''); window.wysiwygEditor.setSelection(0, 0);")
    find(".ql-toolbar button.ql-list[value='bullet']").click
    find(".ql-editor").send_keys("First", :enter, "Second", :enter, :enter)

    expect(page).to have_css(".ql-editor ul > li", count: 2)
    expect(page).to have_css(".ql-editor > p > br", visible: :all)
    click_button save

    expect(page).to have_css(success, text: "updated")
    saved = Nokogiri::HTML.fragment(club.reload.notes)
    expect(saved.children.map(&:name)).to eq %w[ul p]
    expect(saved.css("ul > li").map(&:text)).to eq ["First", "Second"]
    expect(saved.at_css("p > br")).to be_present
  end

  it "preserves legacy shortcut text when HTML notes are turned into bullets and saved again" do
    shortcuts = [
      "[EXL:https://ulsterchess.org/:Club website:target=ulster]",
      "[EMA:secretary@icu.ie:Club secretary]",
      "[FEN:k7/8/8/8/8/8/8/7K w:right:White to play]",
      "[RTN:123:Ratings]",
    ]
    club = create(:club, markdown: false, notes: shortcuts.map { |shortcut| "<p>#{shortcut}</p>" }.join)
    login "editor"
    visit edit_admin_club_path(club)

    expect(page).to have_css(".ql-editor")
    page.execute_script("window.wysiwygEditor.setSelection(0, window.wysiwygEditor.getLength() - 1);")
    find(".ql-toolbar button.ql-list[value='bullet']").click
    expect(page).to have_css(".ql-editor ul > li", count: shortcuts.length)
    click_button save

    expect(page).to have_css(success, text: "updated")
    notes = club.reload.notes
    expect(Nokogiri::HTML.fragment(notes).css("ul > li").map(&:text)).to eq shortcuts
    expect(page).to have_css("#description a[href='https://ulsterchess.org/'][target='ulster']", text: "Club website")
    expect(page).to have_css("#description .board")
    expect(page).to have_no_content("editor shortcut error")

    visit edit_admin_club_path(club)
    expect(page).to have_css(".ql-editor ul > li", count: shortcuts.length)
    click_button save

    expect(page).to have_css(success, text: "updated")
    expect(club.reload.notes).to eq notes
  end
end
