require 'rails_helper'

describe "Event chart access", type: :request do
  let(:user) { create(:user, roles: "organiser") }
  let(:event) { create(:event) }
  let!(:access) { create(:event_user, event: event, user: user, role: "full_access") }
  before { post sessions_path, params: { email: user.email, password: "password" } }

  it "allows full-access organisers and editors" do
    %w[organiser editor].each do |role|
      user.update!(roles: role)
      get admin_event_path(event)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="event-entries"')
      get entries_chart_admin_event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  it "allows organiser and editor owners without an EventUser record" do
    access.destroy!
    event.update!(user: user)
    %w[organiser editor].each do |role|
      user.update!(roles: role)
      get entries_chart_admin_event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  %w[admin treasurer].each do |role|
    it "allows #{role}s without an EventUser record" do
      access.destroy!
      user.update!(roles: role)
      get admin_event_path(event)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="event-entries"')
      get entries_chart_admin_event_path(event)
      expect(response).to have_http_status(:ok)
    end
  end

  it "denies limited access" do
    access.update!(role: "limited_access")
    get admin_event_path(event)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('id="event-entries"')
    get entries_chart_admin_event_path(event)
    expect(response).to redirect_to(sign_in_path)
  end

  it "denies organisers without access to the event" do
    access.destroy!
    get entries_chart_admin_event_path(event)
    expect(response).to redirect_to(sign_in_path)
  end

  it "denies access after organiser privileges are removed" do
    user.update!(roles: nil)
    get entries_chart_admin_event_path(event)
    expect(response).to redirect_to(sign_in_path)
  end
end
