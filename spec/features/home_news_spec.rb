require 'rails_helper'

describe "News item button on the home page" do
  let(:add_news) { I18n.t("pages.news.add") }

  %w[admin editor organiser].each do |role|
    it "is visible to users with the #{role} role" do
      login role
      visit home_path

      within ".latest-news > header" do
        expect(page).to have_link(add_news, href: new_admin_news_path)
      end
    end
  end

  %w[guest member reporter].each do |role|
    it "is hidden from #{role} users" do
      login role
      visit home_path

      within ".latest-news > header" do
        expect(page).to_not have_link(add_news)
        expect(page).to_not have_link(href: new_admin_news_path)
      end
    end
  end
end

describe "News list on the home page" do
  let(:image) { create(:image) }
  let!(:with_image)    { create(:news, headline: "With image", image: image, date: Date.new(2026, 10, 1)) }
  let!(:without_image) { create(:news, headline: "Without image", date: Date.new(2026, 10, 2)) }

  it "shows the image beside the text if there is one, and the date but not the author" do
    visit home_path

    within(".news-item", text: "With image") do
      expect(page).to have_link("With image", href: news_path(with_image))
      expect(page).to have_css(".news-item-image img[src='#{image.data.url}']")
      expect(page).to have_css("time.news-item-date", text: "1 Oct 2026")
      expect(page).to_not have_content(with_image.user.player.name)
    end
    within(".news-item", text: "Without image") do
      expect(page).to_not have_css(".news-item-image")
      expect(page).to have_css("time.news-item-date", text: "2 Oct 2026")
    end
  end

  it "shows editor text without paragraph margins, but keeps them for markdown" do
    create(:news, headline: "Editor news", markdown: false, summary: "<p>One</p><p>Two</p>")
    create(:news, headline: "Markdown news", markdown: true, summary: "One\n\nTwo")
    visit home_path

    expect(page).to have_css(".news-item", text: "Editor news") { |item| item.has_css?(".news.wysiwyg-content p") }
    expect(page).to have_css(".news-item", text: "Markdown news") { |item| item.has_css?(".news p") && item.has_no_css?(".wysiwyg-content") }
  end
end

describe "News on the home page", js: true do
  let(:show_more) { I18n.t("pages.news.show_more") }
  let(:show_less) { I18n.t("pages.news.show_less") }

  let!(:short_news) { create(:news, headline: "Short news", summary: "Just one line.", date: Date.today) }
  let!(:four_lines) { create(:news, headline: "Four lines", summary: "Line one.  \nLine two.  \nLine three.  \nLine four.", date: Date.today) }
  let!(:long_news)  { create(:news, headline: "Long news", summary: (1..40).map { |i| "Paragraph #{i}." }.join("\n\n"), date: Date.yesterday) }
  let!(:link_news)  { create(:news, headline: "Link news", summary: "[Top link](/clubs)\n\n" + (1..20).map { |i| "Section #{i}." }.join("\n\n") + "\n\n[Bottom link](/events)", date: Date.yesterday - 1) }

  let(:short_panel) { find(".news-item", text: "Short news") }
  let(:four_panel)  { find(".news-item", text: "Four lines") }
  let(:long_panel)  { find(".news-item", text: "Long news") }
  let(:link_panel)  { find(".news-item", text: "Link news") }

  before(:each) do
    visit home_path
  end

  it "only offers Show more for news that's too long" do
    expect(long_panel).to have_link(show_more)
    expect(short_panel).to_not have_link(show_more)
    expect(four_panel).to_not have_link(show_more)
    expect(four_panel).to have_text("Line four.")
    expect(long_panel).to_not have_text("Paragraph 40.")
    expect(long_panel).to_not have_text("Paragraph 6.")
  end

  it "expands and collapses long news" do
    long_panel.click_link(show_more)
    expect(long_panel).to have_text("Paragraph 40.")
    expect(long_panel).to have_link(show_less)

    long_panel.click_link(show_less)
    expect(long_panel).to_not have_text("Paragraph 40.")
    expect(long_panel).to have_link(show_more)
  end

  it "expands when the keyboard focus moves to a cut-off link" do
    expect(link_panel).to have_link(show_more)

    page.execute_script("document.querySelector('.news-item a[href=\"/clubs\"]').focus()")
    expect(link_panel).to have_link(show_more)
    expect(link_panel).to_not have_text("Section 20.")

    page.execute_script("document.querySelector('.news-item a[href=\"/events\"]').focus()")
    expect(link_panel).to have_link(show_less)
    expect(link_panel).to have_text("Section 20.")
    expect(link_panel).to have_link("Bottom link")
  end

  it "shows news in full on its own page" do
    visit news_path(long_news)
    expect(page).to have_css(".news-item", text: "Paragraph 40.")
    expect(page).to_not have_link(show_more)
    expect(page).to_not have_css(".show-more-content")
  end
end
