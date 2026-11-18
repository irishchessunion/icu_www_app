require 'rails_helper'

describe "Admin event users", type: :request do
  let(:owner) { create(:user, roles: "organiser") }
  let(:event) { create(:event, user: owner) }
  let(:user) { create(:user, roles: "organiser") }

  before { post sessions_path, params: { email: owner.email, password: "password" } }

  def expect_event_redirect(message)
    expect(response).to redirect_to admin_event_path(event)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(message)
  end

  it "redirects to the event after adding an organiser" do
    post admin_event_event_users_path(event), params: { event_user: { user_id: user.id, role: "full_access" } }

    expect(event.event_users.pluck(:user_id, :role)).to eq [[user.id, "full_access"]]
    expect_event_redirect I18n.t("event.admin.user_added")
  end

  it "redirects back with validation errors when the access level is invalid" do
    post admin_event_event_users_path(event), params: { event_user: { user_id: user.id, role: "invalid" } }

    expect(event.event_users).to be_empty
    expect_event_redirect "Role #{I18n.t('errors.messages.inclusion')}"
  end

  it "redirects to the event after removing an organiser" do
    access = create(:event_user, event: event, user: user)
    delete admin_event_event_user_path(event, access)

    expect(event.event_users).to be_empty
    expect_event_redirect I18n.t("event.admin.user_removed")
  end
end
