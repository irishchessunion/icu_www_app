require 'rails_helper'

describe "Login session persistence", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  before do
    freeze_time
    post sessions_path, params: { email: user.email, password: "password" }
  end

  after do
    travel_back
  end

  def session_cookie(response)
    Array(response.headers["set-cookie"]).find { |header| header.start_with?("_www_session=") }
  end

  it "issues a persistent cookie lasting 14 days" do
    expect(session[:user_id]).to eq user.id
    expect(session_cookie(response)).to include("expires=#{(Time.now + 14.days).httpdate}")
  end

  it "restores the login in a fresh browser session and renews its expiry on a visit" do
    cookie = session_cookie(response).split(";", 2).first
    travel 13.days

    browser = ActionDispatch::Integration::Session.new(Rails.application)
    browser.get account_path(user), headers: { "HTTP_COOKIE" => cookie }

    expect(browser.response).to have_http_status(:ok)
    expect(browser.request.session[:user_id]).to eq user.id
    expect(session_cookie(browser.response)).to include("expires=#{(Time.now + 14.days).httpdate}")
  end

  it "requires login again after 14 days without a visit" do
    cookie = session_cookie(response).split(";", 2).first
    travel 15.days

    browser = ActionDispatch::Integration::Session.new(Rails.application)
    # Send the expired cookie explicitly to check server-side expiry too.
    browser.get account_path(user), headers: { "HTTP_COOKIE" => cookie }

    expect(browser.response).to have_http_status(:found)
    expect(URI(browser.response.location).path).to eq sign_in_path
    expect(browser.request.session[:user_id]).to be_nil
  end
end
