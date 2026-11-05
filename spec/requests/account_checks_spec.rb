require 'rails_helper'

describe "Account checks", type: :request do
  let(:user) { create(:user) }

  def reset_password(user)
    user.update_columns(reset_password_token: "abc123", reset_password_sent_at: Time.now)
    put password_path, params: { token: "abc123", new_password: "newpass99", new_password_confirmation: "newpass99" }
  end

  context "resetting a password" do
    it "asks the user to sign in, rather than signing them in" do
      reset_password(user)

      expect(response).to redirect_to sign_in_path
      expect(session[:user_id]).to be_nil
      expect(user.reload.reset_password_token).to be_nil
    end

    it "doesn't let a disabled account back in" do
      user.update_column(:status, "Disabled")
      reset_password(user)

      post sessions_path, params: { email: user.email, password: "newpass99" }
      expect(session[:user_id]).to be_nil
    end
  end

  context "a signed in user whose account is then disabled" do
    it "is signed out on their next request" do
      post sessions_path, params: { email: user.email, password: "password" }
      expect(session[:user_id]).to eq user.id

      user.update_column(:status, "Disabled")
      get account_path(user)
      expect(session[:user_id]).to be_nil
    end
  end

  context "signing up" do
    # The test environment doesn't cache anything, so pretend that the count of attempts has reached this number.
    it "is refused over the limit" do
      allow(Rails.cache).to receive(:increment).and_return(6)
      post users_path, params: { user: { player_id: 1, ticket: "x", email: "x@example.com", password: "password1" } }

      expect(response).to redirect_to sign_up_path
      expect(flash[:alert]).to eq I18n.t("session.too_many_attempts")
    end
  end
end
