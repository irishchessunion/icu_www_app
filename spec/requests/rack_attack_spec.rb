require 'rails_helper'

describe "Rack::Attack", type: :request do
  # The test environment doesn't cache anything, so give Rack::Attack a real store to count in.
  around(:each) do |example|
    store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store = store
  end

  let(:probe) { { item: { type: "Item::Subscription'; waitfor delay '0:0:15' -- " } } }

  it "lets normal requests through" do
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "refuses SQL injection in posted parameters" do
    post items_path, params: probe
    expect(response).to have_http_status(:forbidden)
  end

  it "refuses SQL injection in the query string" do
    get players_path, params: { last_name: "x' UNION SELECT password FROM users --" }
    expect(response).to have_http_status(:forbidden)
  end

  it "refuses SQL injection in the path" do
    get "/news/4306-1))%20OR%20977=(SELECT%20977%20FROM%20PG_SLEEP(15))--"
    expect(response).to have_http_status(:forbidden)
  end

  it "refuses Oracle SQL injection" do
    post items_path, params: { item: { type: "Item::Subscription'||DBMS_PIPE.RECEIVE_MESSAGE(CHR(98)||CHR(98)||CHR(98),15)||'" } }
    expect(response).to have_http_status(:forbidden)
  end

  it "refuses requests for other platforms' files" do
    get "/wp-login.php"
    expect(response).to have_http_status(:forbidden)
  end

  it "bans an IP after 3 probes, even for normal requests" do
    get root_path
    expect(response).to have_http_status(:ok)

    3.times { post items_path, params: probe }
    get root_path
    expect(response).to have_http_status(:forbidden)
  end

  it "throttles an IP that sends too many requests" do
    allow(Rack::Attack.cache.store).to receive(:increment).and_return(301)
    get root_path
    expect(response).to have_http_status(:too_many_requests)
  end
end
