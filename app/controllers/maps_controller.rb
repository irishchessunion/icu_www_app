class MapsController < ApplicationController
  CENTER = [53.5, -8.1]
  IN = 14
  OUT = 6

  def clubs
    @clubs = Club.active.with_geocodes
    id = params[:id].to_i
    club = @clubs.find { |c| c.id == id } if id > 0
    if club
      @center = [club.lat, club.long]
      @zoom = IN
    else
      @active = Club.active.count
      @center = CENTER
      @zoom = OUT
    end
  end

  def events
    @events = Event.active.with_geocodes.where("start_date >= ?", Date.today)
    id = params[:id].to_i
    event = @events.find { |e| e.id == id } if id > 0
    if event
      @center = [event.lat, event.long]
      @zoom = IN
    else
      @forthcoming = Event.active.where("start_date >= ?", Date.today).count
      @center = CENTER
      @zoom = OUT
    end
  end
end
