require 'rails_helper'

describe "News on the home page", js: true do
  let(:show_more) { I18n.t("pages.news.show_more") }
  let(:show_less) { I18n.t("pages.news.show_less") }

  let!(:short_news) { create(:news, headline: "Short news", summary: "Just one line.", date: Date.today) }
  let!(:four_lines) { create(:news, headline: "Four lines", summary: "Line one.  \nLine two.  \nLine three.  \nLine four.", date: Date.today) }
  let!(:long_news)  { create(:news, headline: "Long news", summary: (1..40).map { |i| "Paragraph #{i}." }.join("\n\n"), date: Date.yesterday) }

  let(:short_panel) { find(".panel-news", text: "Short news") }
  let(:four_panel)  { find(".panel-news", text: "Four lines") }
  let(:long_panel)  { find(".panel-news", text: "Long news") }

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
end
