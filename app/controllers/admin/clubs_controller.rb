class Admin::ClubsController < ApplicationController
  before_action :set_club, only: [:edit, :update]
  authorize_resource

  def new
    @club = Club.new
  end

  def create
    @club = Club.new(club_params)
    clear_legacy_meet_if_first_meeting

    if @club.save
      @club.journal(:create, current_user, request.remote_ip)
      journal_meetings("")
      redirect_to @club, notice: "Club was successfully created"
    else
      render action: "new"
    end
  end

  def update
    previous_meetings = meeting_summary
    @club.assign_attributes(club_params)
    clear_legacy_meet_if_first_meeting
    if @club.save
      @club.journal(:update, current_user, request.remote_ip)
      journal_meetings(previous_meetings)
      redirect_to @club, notice: "Club was successfully updated"
    else
      flash_first_error(@club, base_only: true)
      render action: "edit"
    end
  end

  private

  def clear_legacy_meet_if_first_meeting
    meetings = @club.club_meetings.to_a
    @club.meet = nil if meetings.any?(&:new_record?) && meetings.none?(&:persisted?)
  end

  def meeting_summary
    @club.club_meetings.order(:id).map do |meeting|
      [meeting.id, meeting.day_of_week, meeting.start_time&.strftime("%H:%M"), meeting.audience,
       meeting.welcomes_juniors, meeting.notes, meeting.title].join(" / ")
    end.join("; ")
  end

  def journal_meetings(before)
    after = meeting_summary
    return if before == after

    from, to = Util::Diff.new(before, after).difference
    @club.journal_entries.create!(action: "update", column: "meetings", from: from, to: to,
                                  by: current_user.signature, ip: request.remote_ip)
  end

  def set_club
    @club = Club.find(params[:id])
  end

  def club_params
    params[:club].permit(:name, :web, :meet, :address, :district, :city, :county, :eircode, :lat, :long, :contact,
                         :email, :phone, :junior_only, :has_junior_section, :active, :description, :notes, :secretary_id,
                         club_meetings_attributes: [:id, :day_of_week, :start_time, :title, :notes, :audience, :welcomes_juniors, :_destroy])
  end
end
