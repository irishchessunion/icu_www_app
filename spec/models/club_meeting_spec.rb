require 'rails_helper'

describe ClubMeeting do
  let(:club) { create(:club) }

  it "must have a valid day, start time and audience" do
    meeting = club.club_meetings.build(day_of_week: "tuesday", start_time: "19:00")
    meeting.day_of_week = "someday"
    meeting.audience = "unknown"
    meeting.start_time = nil
    expect(meeting).not_to be_valid
    expect(meeting.errors.attribute_names).to include(:day_of_week, :audience, :start_time)
  end
end
