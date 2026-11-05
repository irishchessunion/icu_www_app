require 'rails_helper'

describe Sponsor do
  def sponsor(weblink)
    Sponsor.new(name: "Sponsor", weight: 100, weblink: weblink)
  end

  it "accepts a web link" do
    expect(sponsor("https://www.cpl.ie/Home")).to be_valid
  end

  it "rejects a link that isn't to a web page, as visitors are redirected to it" do
    expect(sponsor("javascript:alert(1)")).to_not be_valid
    expect(sponsor("www.cpl.ie")).to_not be_valid
  end
end
