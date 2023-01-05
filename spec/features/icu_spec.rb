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

    it "anyone can see all docs" do
      Global::ICU_DOCS.keys.each do |key|
        if key
          visit self.send("icu_#{key}_path")
          expect(page).to_not have_css(failure)
          expect(page).to have_title(I18n.t("icu.#{key}"))
        end
      end
    end
  end
end
