require 'rails_helper'

describe Article do
  let(:admin)  { create(:user, roles: "admin") }
  let(:editor) { create(:user, roles: "editor") }
  let(:guest)  { User::Guest.new }
  let(:member) { create(:user) }

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
      expect(Article::CATEGORIES.include?("women")).to be(true)
    end
  end
end
