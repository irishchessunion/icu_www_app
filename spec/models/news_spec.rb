require 'rails_helper'

describe News do
  context "#html" do
    let(:news)   { build(:news_extra) }
    let!(:event) { create(:event, id: 98) }

    it "various substitutions" do
      str = news.html
      expect(str).to match "Täby, Sweden"
      expect(str).to match "<h4>Galway Blitz</h4>"
      expect(str).to match %q{John Alfred&#39;s}
      expect(str).to match %q{working on it &#9786;.}
      expect(str).to match %q{<a href="http://www.scandinavian-chess.se/index.asp">Ladies Open</a>}
      expect(str).to match %q{<a href="/events/98">monthly rapidplay</a>}
      expect(str).to match /Entries to me via <script>liame\([^)]+\)<\/script>/
    end
  end

  context "validation" do
    it "rejects an empty Quill editor's placeholder markup as blank summary" do
      news = build(:news, markdown: false, summary: "<p><br></p>")
      expect(news).to_not be_valid
      expect(news.errors[:summary]).to include("can't be blank")
    end

    it "also rejects a blank summary when updating an existing news item" do
      news = create(:news, markdown: false)
      news.summary = "<p><br></p>"
      expect(news).to_not be_valid
      expect(news.errors[:summary]).to include("can't be blank")
    end
  end

  context "summary sanitization" do
    it "strips script tags and event handler attributes from HTML summary on save" do
      news = create(:news, markdown: false, summary: %q{<p onmouseover="alert(1)">Hi<script>alert(1)</script></p>})
      expect(news.summary).to_not include("<script>")
      expect(news.summary).to_not include("onmouseover")
      expect(news.summary).to include("Hi")
    end

    it "leaves markdown-source summary untouched" do
      news = create(:news, markdown: true, summary: "Some *markdown* text")
      expect(news.summary).to eq("Some *markdown* text")
    end
  end

  context "#editor_html" do
    it "renders markdown summary to HTML without expanding shortcodes" do
      news = build(:news, markdown: true, summary: "**Bold** [ART:1:Some Title]")
      expect(news.editor_html).to include("<strong>Bold</strong>")
      expect(news.editor_html).to include("[ART:1:Some Title]")
    end

    it "returns HTML summary as-is without expanding shortcodes" do
      news = build(:news, markdown: false, summary: "<p>Hello</p> [IMG:1]")
      expect(news.editor_html).to eq("<p>Hello</p> [IMG:1]")
    end
  end
end
