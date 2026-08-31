require 'rails_helper'

describe Article do
  let(:admin)  { create(:user, roles: "admin") }
  let(:editor) { create(:user, roles: "editor") }
  let(:guest)  { User::Guest.new }
  let(:member) { create(:user) }

  let(:image1) { create(:image) }
  let(:image2) { create(:image_april) }
  let(:image3) { create(:image_suzanne) }

  def accs(user)
    Article.accessibilities_for(user).join("|")
  end

  context "::accessible_for" do
    it "admin" do
      expect(accs(admin)).to eq "all|members|editors|admins"
    end

    it "editor" do
      expect(accs(editor)).to eq "all|members|editors"
    end

    it "member" do
      expect(accs(member)).to eq "all|members"
    end

    it "guest" do
      expect(accs(guest)).to eq "all"
    end
  end

  context "#accessible_to?" do
    it "everyone" do
      article = create(:article, access: "all")
      expect(article.accessible_to?(admin)).to be true
      expect(article.accessible_to?(editor)).to be true
      expect(article.accessible_to?(member)).to be true
      expect(article.accessible_to?(guest)).to be true
    end

    it "members only" do
      article = create(:article, access: "members")
      expect(article.accessible_to?(admin)).to be true
      expect(article.accessible_to?(editor)).to be true
      expect(article.accessible_to?(member)).to be true
      expect(article.accessible_to?(guest)).to be false
    end

    it "editors only" do
      article = create(:article, access: "editors")
      expect(article.accessible_to?(admin)).to be true
      expect(article.accessible_to?(editor)).to be true
      expect(article.accessible_to?(member)).to be false
      expect(article.accessible_to?(guest)).to be false
    end

    it "admins only" do
      article = create(:article, access: "admins")
      expect(article.accessible_to?(admin)).to be true
      expect(article.accessible_to?(editor)).to be false
      expect(article.accessible_to?(member)).to be false
      expect(article.accessible_to?(guest)).to be false
    end
  end

  context "validation" do
    it "invalid" do
      article = build(:article, access: "INVALID")
      expect(article).to_not be_valid
    end

    it "rejects an empty Quill editor's placeholder markup as blank text" do
      article = build(:article, markdown: false, text: "<p><br></p>")
      expect(article).to_not be_valid
      expect(article.errors[:text]).to include("can't be blank")
    end
  end

  context "text sanitization" do
    it "strips script tags and event handler attributes from HTML text on save" do
      article = create(:article, markdown: false, text: %q{<p onmouseover="alert(1)">Hi<script>alert(1)</script></p>})
      expect(article.text).to_not include("<script>")
      expect(article.text).to_not include("onmouseover")
      expect(article.text).to include("Hi")
    end

    it "leaves markdown-source text untouched" do
      article = create(:article, markdown: true, text: "Some *markdown* text")
      expect(article.text).to eq("Some *markdown* text")
    end
  end

  context "categories" do
    it "includes women" do
      expect(CategoriesOwner::CATEGORIES.include?("women")).to be(true)
    end
  end

  context "thumbnail image" do
    it "extracts the first image ID from text" do
      article = build(:article, text: "testing123 [IMG:#{image1.id}:width=250:left] ending")
      expect(article.thumbnail_image_id).to eq(image1.id)
    end

    it "returns the Image for the first IMG tag" do
      article = create(:article, text: "Hello World! [IMG:#{image2.id}] Goodbye World!")
      expect(article.thumbnail_image).to eq(image2)
    end

    it "extracts only the first IMG tag if multiple tags are present" do
      article = build(
        :article,
        text: "[IMG:#{image1.id}] and John won the top section [IMG:#{image2.id}] and the €5Million prize [IMG:#{image3.id}]"
      )
      expect(article.thumbnail_image_id).to eq(image1.id)
      expect(article.thumbnail_image).to eq(image1)
    end

    it "returns nil if there is no IMG tag" do
      article = build(:article, text: "No images here")
      expect(article.thumbnail_image_id).to be_nil
      expect(article.thumbnail_image).to be_nil
    end

    it "returns nil if the IMG ID does not exist" do
      article = build(:article, text: "[IMG:99999999]")
      expect(article.thumbnail_image).to be_nil
    end

  end

  context "#editor_html" do
    it "renders markdown text to HTML without expanding shortcodes" do
      article = build(:article, markdown: true, text: "**Bold** [ART:#{image1.id}:Some Title]")
      expect(article.editor_html).to include("<strong>Bold</strong>")
      expect(article.editor_html).to include("[ART:#{image1.id}:Some Title]")
    end

    it "returns HTML text as-is without expanding shortcodes" do
      article = build(:article, markdown: false, text: "<p>Hello</p> [IMG:#{image1.id}]")
      expect(article.editor_html).to eq("<p>Hello</p> [IMG:#{image1.id}]")
    end
  end
end
