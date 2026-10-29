require 'rails_helper'

describe "Admin overview", type: :request do
  %w[admin treasurer].each do |role|
    it "is accessible to a #{role}" do
      user = create(:user, roles: role)
      post sessions_path, params: { email: user.email, password: "password" }

      get admin_overview_path

      expect(response).to have_http_status(:ok)

      get admin_overview_new_players_path, params: { period: "season" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("categories").size).to eq 8
      expect(response.parsed_body.fetch("series").keys).to eq %w[accounts age gender]
    end
  end

  [nil, "organiser", "reporter"].each do |role|
    it "requires overview access for a #{role || 'regular member'}" do
      user = create(:user, roles: role)
      post sessions_path, params: { email: user.email, password: "password" }

      get admin_overview_path

      expect(response).to redirect_to sign_in_path

      get admin_overview_new_players_path

      expect(response).to redirect_to sign_in_path
    end
  end

  it "requires sign in for a guest" do
    get admin_overview_path

    expect(response).to redirect_to sign_in_path

    get admin_overview_new_players_path

    expect(response).to redirect_to sign_in_path
  end

  it "rejects unsupported chart periods" do
    user = create(:user, roles: "admin")
    post sessions_path, params: { email: user.email, password: "password" }

    get admin_overview_new_players_path, params: { period: "invalid" }

    expect(response).to have_http_status(:bad_request)
  end
end
