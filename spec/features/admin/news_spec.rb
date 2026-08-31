require 'rails_helper'

describe News do
  include_context "features"

  let(:headline) { I18n.t("news.headline") }
  let(:summary)  { I18n.t("news.summary") }

  let(:user) { create(:user, roles: "editor") }

  context "authorization" do
    let(:panel)  { ".panel-heading" }
    let(:level1) { ["admin", user] }
    let(:level2) { ["editor", "organiser"] }
    let(:level3) { User::ROLES.reject { |r| level1.include?(r) || level2.include?(r) }.append("guest") }
    let(:news)   { create(:news, user: user) }

    it "level 1 can update and delete as well as create and show" do
      level1.each do |role|
        login role
        visit new_admin_news_path
        expect(page).to_not have_css(failure)
        visit edit_admin_news_path(news)
        expect(page).to_not have_css(failure)
        visit news_index_path
        click_link news.headline
        expect(page).to have_css(panel, text: news.headline)
        expect(page).to have_link(edit)
        expect(page).to have_link(delete)
      end
    end

    it "level 2 can't update or delete" do
      level2.each do |role|
        login role
        visit new_admin_news_path
        expect(page).to_not have_css(failure)
        visit edit_admin_news_path(news)
        expect(page).to have_css(failure, text: unauthorized)
        visit news_path(news)
        expect(page).to have_css(panel, text: news.headline)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end

    it "level 3 can only index and show" do
      level3.each do |role|
        login role
        visit new_admin_news_path
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_news_path(news)
        expect(page).to have_css(failure, text: unauthorized)
        visit news_path(news)
        expect(page).to have_css(panel, text: news.headline)
        expect(page).to_not have_link(edit)
        expect(page).to_not have_link(delete)
      end
    end
  end

  context "create" do
    let(:data) { build(:news) }

    before(:each) do
      login user
      visit new_admin_news_path
    end

    it "defaulted date" do

      fill_in headline, with: data.headline
      fill_in summary, with: data.summary
      check active if data.active
      click_button save

      expect(page).to have_css(success, text: created)
      expect(News.count).to eq 1
      news = News.first

      expect(news.active).to eq data.active
      expect(news.date).to eq Date.today
      expect(news.headline).to eq data.headline
      expect(news.summary).to eq data.summary
      expect(news.user_id).to eq user.id

      expect(JournalEntry.news.where(action: "create", by: user.signature, journalable_id: news.id).count).to eq 1
    end

    it "invalid expansion" do
      fill_in headline, with: data.headline
      fill_in summary, with: data.summary + "\n\n[ART:99:Further details].\n"
      click_button save

      expect(page).to have_css(failure, text: "valid")
      expect(News.count).to eq 0
      expect(JournalEntry.count).to eq 0
    end

    it "subsequently invalid expansion" do
      article = create(:article)
      fill_in headline, with: data.headline
      fill_in summary, with: data.summary + "\n\n[ART:#{article.id}:Further details].\n"
      click_button save

      expect(page).to_not have_css(failure)
      expect(News.count).to eq 1
      expect(JournalEntry.count).to eq 1

      article.destroy

      news = News.first
      visit news_path(news)
      expect(page).to have_content("(editor shortcut error:")
    end
  end

  context "edit" do
    let(:news) { create(:news, user: user, active: true, date: Date.today) }

    before(:each) do
      login user
      visit news_path(news)
      click_link edit
    end

    it "active" do
      uncheck active
      click_button save

      expect(page).to have_css(success, text: updated)
      news.reload
      expect(news.active).to be false

      expect(JournalEntry.news.where(action: "update", by: user.signature, journalable_id: news.id, column: "active").count).to eq 1
    end

    # Test removed since the form has no date field
    # it "date" do
    #   fill_in date, with: Date.tomorrow.to_s
    #   click_button save

    #   expect(page).to have_css(field_error, text: "on or before #{Date.today}")

    #   fill_in date, with: Date.yesterday.to_s
    #   click_button save

    #   expect(page).to have_css(success, text: updated)

    #   news.reload
    #   expect(news.date).to eq Date.yesterday

    #   expect(JournalEntry.news.where(action: "update", by: user.signature, journalable_id: news.id, column: "date").count).to eq 1
    # end
  end

  context "delete" do
    let(:user) { create(:user, roles: "editor") }
    let(:news) { create(:news, user: user) }

    it "destroy" do
      login user
      visit news_path(news)
      click_link delete
      expect(page).to have_css(success, text: deleted)

      expect(News.count).to be 0
      expect(JournalEntry.news.where(action: "destroy", by: user.signature, journalable_id: news.id).count).to eq 1
    end
  end

  context "editor", js: true do
    let!(:linked_article) { create(:article, title: "Linked Article") }
    let!(:linked_event)   { create(:event, name: "Linked Event") }
    let!(:linked_image)   { create(:image, caption: "Linked Image") }

    def set_editor_html(html)
      expect(page).to have_css("#wysiwyg_editor_mount .ql-editor", wait: 5)
      page.execute_script("document.querySelector('#wysiwyg_editor_mount').__quill.root.innerHTML = #{html.to_json};")
    end

    before(:each) do
      login user
      wait_a_second(0.2)
      visit new_admin_news_path
    end

    it "creates a news item with quick-links inserted via the pickers" do
      fill_in headline, with: "My News"

      set_editor_html("<p>Some intro text.</p>")

      find("#wysiwyg_toolbar_extra button", text: "Link Article").click
      within "#article_ids_modal" do
        fill_in I18n.t("article.title"), with: linked_article.title + force_submit
        click_link linked_article.title
      end
      wait_a_second(0.5)

      find("#wysiwyg_toolbar_extra button", text: "Link Event").click
      within "#event_ids_modal" do
        fill_in I18n.t("event.name"), with: linked_event.name + force_submit
        click_link linked_event.name
      end
      wait_a_second(0.5)

      find("#wysiwyg_toolbar_extra button", text: "Insert Image").click
      within "#image_ids_modal" do
        fill_in I18n.t("image.caption"), with: linked_image.caption + force_submit
        click_link linked_image.caption
      end
      wait_a_second(0.5)

      click_button save

      expect(page).to have_css(success, text: created)
      news = News.find_by!(headline: "My News")
      expect(news.markdown).to be false
      expect(news.summary).to include("Some intro text.")
      expect(news.summary).to include("[ART:#{linked_article.id}:#{linked_article.title}]")
      expect(news.summary).to include("[EVT:#{linked_event.id}:#{linked_event.name}]")
      expect(news.summary).to include("[IMG:#{linked_image.id}]")
    end
  end
end
