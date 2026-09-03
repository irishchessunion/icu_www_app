require 'rails_helper'

describe WysiwygEditable do
  [
    [Article, :text],
    [News, :summary],
  ].each do |klass, field|
    context klass do
      it "provides editor_html and html" do
        expect(klass.column_names).to include("markdown")
        expect(klass.new).to respond_to(:editor_html)
        expect(klass.new).to respond_to(:html)
      end

      it "rejects an empty Quill editor's placeholder markup as blank #{field}" do
        record = klass.new(markdown: false, field => "<p><br></p>")
        record.valid?
        expect(record.errors[field]).to include("can't be blank")
      end
    end
  end

  # Article's presence check applies on every save; News's only on create -
  # this predates WysiwygEditable and is preserved deliberately (see
  # app/models/news.rb: wysiwyg_editable :summary, on: :create).
  it "checks Article's text on every save, not just create" do
    article = create(:article)
    article.markdown = false
    article.text = "<p><br></p>"
    expect(article).to_not be_valid
    expect(article.errors[:text]).to include("can't be blank")
  end

  it "only checks News's summary on create (existing behaviour)" do
    news = create(:news)
    news.markdown = false
    news.summary = "<p><br></p>"
    expect(news).to be_valid
  end
end
