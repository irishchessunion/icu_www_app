require 'rails_helper'

describe Cart do
  include_context "features"

  context "authorization" do
    let(:level1) { %w[admin treasurer] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) or role == "auditor" }.append("guest") }

    let(:cart)   { create(:cart) }
    let(:paths)  { [admin_carts_path, admin_cart_path(cart), edit_admin_cart_path(cart)] }
    let(:auditor_paths)  { [admin_carts_path, admin_cart_path(cart)] }

    it "level1 can view carts" do
      level1.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to_not have_css(failure)
        end
      end
    end

    it "auditor can view carts but not edit" do
      login "auditor"
      auditor_paths.each do |path|
        visit path
        expect(page).to_not(have_css(failure), "Path is #{path}")
      end
    end

    it "level2 cannot" do
      level2.each do |role|
        login role
        paths.each do |path|
          visit path
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end
  end
end
