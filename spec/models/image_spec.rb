require 'rails_helper'

describe Image do
  context "#expand" do
    let(:image) { create(:image) }

    it "HTML-escapes alt text so it can't break out of the attribute (XSS)" do
      html = image.expand(type: "IMG", alt: %q{" onmouseover="alert(1)})
      expect(html).to_not include(%q{" onmouseover="alert(1)})
      expect(html).to include("&quot; onmouseover=&quot;alert(1)")
    end

    it "HTML-escapes link text for the IML type (XSS)" do
      html = image.expand(type: "IML", text: "<script>alert(1)</script>")
      expect(html).to_not include("<script>")
      expect(html).to include("&lt;script&gt;")
    end
  end
end
