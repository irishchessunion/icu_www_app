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

  it "limits notes to 100 characters" do
    meeting = club.club_meetings.build(day_of_week: "tuesday", start_time: "19:00", notes: "a" * 100)
    expect(meeting).to be_valid

    meeting.notes += "b"
    expect(meeting).not_to be_valid
    expect(meeting.errors.attribute_names).to include(:notes)
  end

  it "requires juniors-only meetings to welcome juniors" do
    meeting = club.club_meetings.build(day_of_week: "tuesday", start_time: "19:00", audience: "juniors_only", welcomes_juniors: false)
    expect(meeting).not_to be_valid
    expect(meeting.errors.attribute_names).to include(:welcomes_juniors)

    meeting.welcomes_juniors = true
    expect(meeting).to be_valid

    meeting.audience = "open"
    meeting.welcomes_juniors = false
    expect(meeting).to be_valid
  end
end
