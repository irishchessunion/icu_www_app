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

  context "links to docs" do
    let(:public_docs)  { Global::PUBLIC_ICU_DOCS }
    let(:members_docs) { Global::ICU_DOCS.keys - public_docs }

    def doc_link(key)
      key == :privacy_policy ? help_privacy_path : send("icu_#{key}_path")
    end

    it "guests only see the public docs in the list" do
      visit icu_documents_path
      public_docs.each { |key| expect(page).to have_link(I18n.t("icu.#{key}"), href: doc_link(key)) }
      members_docs.each { |key| expect(page).to_not have_link(href: doc_link(key)) }

      login user
      visit icu_documents_path
      Global::ICU_DOCS.each_key { |key| expect(page).to have_link(I18n.t("icu.#{key}"), href: doc_link(key)) }
    end

    it "guests only step between the public docs" do
      visit icu_constitution_path
      expect(page).to_not have_link("☜")
      expect(page).to have_link("☞", href: icu_membership_byelaws_path)

      visit icu_membership_byelaws_path
      expect(page).to have_link("☜", href: icu_constitution_path)
      expect(page).to have_link("☞", href: icu_affiliation_byelaws_path)

      login user
      visit icu_membership_byelaws_path
      expect(page).to have_link("☞", href: icu_code_of_conduct_path)
    end

    it "guests don't get links to the eligibility criteria on other pages" do
      visit juniors_path
      expect(page).to_not have_link("Junior Eligibility Criteria")
      visit help_membership_path
      expect(page).to have_link("Membership Bye-laws", href: icu_membership_byelaws_path)
      expect(page).to_not have_link("adult")
      expect(page).to_not have_link("junior", exact: true)
      expect(page).to have_content("represent Ireland as an adult or as a junior")

      login user
      visit juniors_path
      expect(page).to have_link("Junior Eligibility Criteria", href: icu_junior_eligibility_criteria_path)
      visit help_membership_path
      expect(page).to have_link("adult", href: icu_eligibility_criteria_path)
      expect(page).to have_link("junior", href: icu_junior_eligibility_criteria_path, exact: true)
    end
  end
end
