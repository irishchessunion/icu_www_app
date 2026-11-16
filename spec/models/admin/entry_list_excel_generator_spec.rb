require 'rails_helper'

describe Admin::EntryListExcelGenerator do
  it "handles an entrant who has never subscribed" do
    entry = create(:paid_entry_item)
    expect(entry.player.most_recent_subscription).to be_nil
    expect(subject.generate_from_items([entry])).to start_with "PK" # an xlsx file is a zip
  end
end
