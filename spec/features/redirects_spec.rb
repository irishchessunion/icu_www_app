require 'rails_helper'

describe "Switch locales" do
  it "guest switches to Irish, from config/locales/ga.yml, and back" do
    visit root_path
    click_link "Irish"
    expect(page).to have_link("Teanga")
    expect(page).to have_link("Gaeilge")

    click_link "Béarla"
    expect(page).to have_link("Language")
    expect(page).to have_link("Irish")
  end
end
