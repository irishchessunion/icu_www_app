require "rails_helper"

describe Event do
  let(:jan) { I18n.t("month.s01") }
  let(:dec) { I18n.t("month.s12") }

  context "multiyear_dates_as_spans" do
    it "returns an array with start date, separator and end date (including year)" do
      start_date = Date.new(2025, 12, 30)
      end_date   = Date.new(2026, 1, 2)

      event = Event.new(start_date: start_date, end_date: end_date)

      expect(event.multiyear_dates_as_spans).to eq(
        ["30 #{dec} 2025", "–", "2 #{jan} 2026"]
      )
    end
  end

end
