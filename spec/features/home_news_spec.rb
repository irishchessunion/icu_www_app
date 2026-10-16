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

describe "News on the home page", js: true do
  let(:show_more) { I18n.t("pages.news.show_more") }
  let(:show_less) { I18n.t("pages.news.show_less") }

  let!(:short_news) { create(:news, headline: "Short news", summary: "Just one line.", date: Date.today) }
  let!(:four_lines) { create(:news, headline: "Four lines", summary: "Line one.  \nLine two.  \nLine three.  \nLine four.", date: Date.today) }
  let!(:long_news)  { create(:news, headline: "Long news", summary: (1..40).map { |i| "Paragraph #{i}." }.join("\n\n"), date: Date.yesterday) }
  let!(:link_news)  { create(:news, headline: "Link news", summary: "[Top link](/clubs)\n\n" + (1..20).map { |i| "Section #{i}." }.join("\n\n") + "\n\n[Bottom link](/events)", date: Date.yesterday - 1) }

  let(:short_panel) { find(".panel-news", text: "Short news") }
  let(:four_panel)  { find(".panel-news", text: "Four lines") }
  let(:long_panel)  { find(".panel-news", text: "Long news") }
  let(:link_panel)  { find(".panel-news", text: "Link news") }

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

    page.execute_script("document.querySelector('.panel-news a[href=\"/clubs\"]').focus()")
    expect(link_panel).to have_link(show_more)
    expect(link_panel).to_not have_text("Section 20.")

    page.execute_script("document.querySelector('.panel-news a[href=\"/events\"]').focus()")
    expect(link_panel).to have_link(show_less)
    expect(link_panel).to have_text("Section 20.")
    expect(link_panel).to have_link("Bottom link")
  end

  it "shows news in full on its own page" do
    visit news_path(long_news)
    expect(page).to have_css(".panel-news", text: "Paragraph 40.")
    expect(page).to_not have_link(show_more)
    expect(page).to_not have_css(".show-more-content")
  end
end
