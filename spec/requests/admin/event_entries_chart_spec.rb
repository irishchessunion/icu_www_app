require 'rails_helper'

describe "Event chart access", type: :request do
  let(:user) { create(:user, roles: "organiser") }
  let(:event) { create(:event) }
  let!(:access) { create(:event_user, event: event, user: user, role: "full_access") }
  before { post sessions_path, params: { email: user.email, password: "password" } }

  it "allows full access, including editor owners" do
    get entries_chart_admin_event_path(event)
    expect(response).to have_http_status(:ok)
    user.update!(roles: "editor")
    event.update!(user: user)
    get entries_chart_admin_event_path(event)
    expect(response).to have_http_status(:ok)
  end

  it "denies limited access" do
    access.update!(role: "limited_access")
    get entries_chart_admin_event_path(event)
    expect(response).to redirect_to(sign_in_path)
  end

  it "denies access after organiser privileges are removed" do
    user.update!(roles: nil)
    get entries_chart_admin_event_path(event)
    expect(response).to redirect_to(sign_in_path)
  end
end
