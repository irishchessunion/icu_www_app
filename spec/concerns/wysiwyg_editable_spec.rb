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

      it "rejects a blank #{field} on update too, not just create" do
        record = create(klass.name.underscore.to_sym)
        record.markdown = false
        record.public_send("#{field}=", "<p><br></p>")
        expect(record).to_not be_valid
        expect(record.errors[field]).to include("can't be blank")
      end
    end
  end
end
