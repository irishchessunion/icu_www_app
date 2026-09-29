require 'rails_helper'

describe IcuMailer do
  describe "#payment_receipt" do
    let(:event)        { create(:event, name: "Bunratty Chess Festival", subscription_required: false) }
    let(:entry_fee)    { create(:entry_fee, event: event) }
    let(:entry)        { create(:paid_entry_item, fee: entry_fee) }
    let(:subscription) { create(:paid_subscription_item) }
    let(:cart)         { create(:cart, status: "paid", payment_method: "stripe", payment_completed: Time.now, total: 85.0) }
    let(:text)         { IcuMailer.payment_receipt(cart.id).body.decoded }

    context "entry item" do
      before(:each) do
        entry.update_column(:cart_id, cart.id)
      end

      it "includes the event name, dates, link and record IDs" do
        expect(text).to include("Event: Bunratty Chess Festival, #{event.start_date} to #{event.end_date}")
        expect(text).to include("http://www.icu.ie/events/#{event.id}")
        expect(text).to include("Fee ID: #{entry_fee.id}, Item ID: #{entry.id}")
        expect(text).to include("quote cart ID #{cart.id}")
      end

      it "copes with a missing fee" do
        entry.update_column(:fee_id, nil)
        expect(text).to include("Fee ID: none, Item ID: #{entry.id}")
        expect(text).to_not include("Event:")
      end
    end

    context "multiple items" do
      before(:each) do
        entry.update_column(:cart_id, cart.id)
        subscription.update_column(:cart_id, cart.id)
      end

      it "shows fee and item IDs for every item but event details only for entries" do
        expect(text).to include("Fee ID: #{entry_fee.id}, Item ID: #{entry.id}")
        expect(text).to include("Fee ID: #{subscription.fee_id}, Item ID: #{subscription.id}")
        expect(text.scan("Event:").size).to eq 1
      end
    end
  end
end
