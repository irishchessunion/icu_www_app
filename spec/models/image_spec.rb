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

    it "uses the original if the image has no styles yet" do
      html = image.expand(type: "IMG", width: "100")
      expect(html).to include(%Q{src="#{image.data.url}"})
      expect(html).to_not include("srcset")
    end
  end

  context "styles" do
    # 500x200, so small is 300x120, medium and large are copies at 500x200
    let(:image) { create(:image, :with_thumbnail) }

    it "are made on upload, along with their dimensions" do
      expect(image.dimensions).to eq(original: [500, 200], thumbnail: [100, 40], small: [300, 120], medium: [500, 200], large: [500, 200])
      Image::STYLES.each_key { |style| expect(File.exist?(image.data.path(style))).to be true }
    end

    it "#expand uses the smallest style that's big enough, and a bigger one for 2x screens" do
      html = image.expand(type: "IMG", width: "250")
      expect(html).to include(%Q{src="#{image.data.url(:small)}"})
      expect(html).to include(%Q{srcset="#{image.data.url(:small)} 1x, #{image.data.url(:medium)} 2x"})
    end

    it "#expand leaves out srcset when there's nothing bigger" do
      html = image.expand(type: "IMG")
      expect(html).to include(%Q{src="#{image.data.url(:medium)}"})
      expect(html).to_not include("srcset")
    end

    it "#generate_styles makes the styles for an older image, without changing updated_at" do
      # Load it afresh, as the factory's own instance has post-processing switched off
      old = Image.find(create(:image).id)
      old.update_column(:updated_at, 1.year.ago)
      updated_at = old.reload.updated_at
      expect(old.styles_generated).to be_empty

      old.generate_styles
      old.reload
      expect(old.styles_generated).to eq Image::STYLES.keys
      expect(old.width(:small)).to eq 300
      expect(File.exist?(old.data.path(:small))).to be true
      expect(old.updated_at).to eq updated_at
    end
  end
end
