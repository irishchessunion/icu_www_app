require 'rails_helper'

describe "Rate limits", type: :request do
  let(:user)     { create(:user) }
  let(:too_many) { I18n.t("session.too_many_attempts") }

  # The test environment doesn't cache anything, so pretend that the count of attempts has reached this number.
  def attempts_so_far(count)
    allow(Rails.cache).to receive(:increment).and_return(count)
  end

  context "signing in" do
    it "is allowed up to the limit" do
      attempts_so_far(10)
      post sessions_path, params: { email: user.email, password: "password" }

      expect(session[:user_id]).to eq user.id
    end

    it "is refused over the limit, even with the right password" do
      attempts_so_far(11)
      post sessions_path, params: { email: user.email, password: "password" }

      expect(response).to redirect_to sign_in_path
      expect(flash[:alert]).to eq too_many
      expect(session[:user_id]).to be_nil
      expect(Login.count).to eq 0
    end
  end

  context "asking for a password reset" do
    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it "is allowed up to the limit" do
      attempts_so_far(5)
      post password_path, params: { email: user.email }

      expect(ActionMailer::Base.deliveries.size).to eq 1
    end

    it "is refused over the limit" do
      attempts_so_far(6)
      post password_path, params: { email: user.email }

      expect(response).to redirect_to new_password_path
      expect(flash[:alert]).to eq too_many
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
