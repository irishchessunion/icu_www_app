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
end
