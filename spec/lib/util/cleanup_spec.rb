require 'rails_helper'

describe Util::Cleanup do
  it "destroys old empty carts when forced, and leaves new ones" do
    old = create(:cart)
    old.update_column(:updated_at, 2.days.ago)
    recent = create(:cart)

    expect { Util::Cleanup.new.empty("f") }.to output(/cleanup empty carts \d{4}-\d\d-\d\d/).to_stdout
    expect(Cart.exists?(old.id)).to be false
    expect(Cart.exists?(recent.id)).to be true
  end

  it "only reports what it would destroy when not forced" do
    create(:cart).update_column(:updated_at, 2.days.ago)
    expect { Util::Cleanup.new.empty }.to output(/would destroy 1 cart/).to_stdout
    expect(Cart.count).to eq 1
  end
end
