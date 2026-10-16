require 'rails_helper'

describe IcuController do
  include_context "features"
  
  let(:user) { create(:user) }
  
  context "authorization" do
    it "guests can only see index, documents and officers" do
      Global::ICU_PAGES.each do |key|
        visit self.send("icu_#{key}_path")
        if %w[index documents officers].include?(key)
          expect(page).to_not have_css(failure)
          expect(page).to have_title(I18n.t("icu.#{key}"))
        else
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end

    it "any logged in user can see all pages" do

      login user
      Global::ICU_PAGES.each do |key|
        visit self.send("icu_#{key}_path")
        expect(page).to_not have_css(failure)
        expect(page).to have_title(I18n.t("icu.#{key}"))
      end
    end

    it "guests can only see the public docs" do
      Global::ICU_DOCS.keys.each do |key|
        visit self.send("icu_#{key}_path")
        if Global::PUBLIC_ICU_DOCS.include?(key)
          expect(page).to_not have_css(failure)
          expect(page).to have_title(I18n.t("icu.#{key}"))
        else
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end

    it "any logged in user can see all docs" do
      login user
      Global::ICU_DOCS.keys.each do |key|
        visit self.send("icu_#{key}_path")
        expect(page).to_not have_css(failure)
        expect(page).to have_title(I18n.t("icu.#{key}"))
      end
    end
  end

  context "docs from the documents table" do
    def create_document(url, current: true)
      Document.create!(title: I18n.t("icu.#{url}"), url: url, content_type: "MARKDOWN", content: "The #{url} text", is_current: current, changed_by: user)
    end

    it "guests can see the current version of a public doc, without the list of versions" do
      create_document("constitution", current: false)
      create_document("constitution")

      visit icu_constitution_path
      expect(page).to_not have_css(failure)
      expect(page).to have_content("The constitution text")
      expect(page).to_not have_link("View")
    end

    it "guests can't see older versions of a public doc" do
      old = create_document("constitution", current: false)
      create_document("constitution")

      visit document_path(old)
      expect(page).to have_css(failure, text: unauthorized)
    end

    it "guests can't see a members only doc, but members can" do
      create_document("code_of_conduct")

      visit icu_code_of_conduct_path
      expect(page).to have_css(failure, text: unauthorized)

      login user
      visit icu_code_of_conduct_path
      expect(page).to have_content("The code_of_conduct text")
      expect(page).to have_link("View")
    end
  end
end
