# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::EventIdsController, type: :controller do
  let(:editor)  { create(:user, roles: 'editor') }
  let!(:sligo)  { create(:event, name: "Sligo Congress") }
  let!(:ennis)  { create(:event, name: "Ennis Congress") }

  describe "GET #index" do
    it "returns a successful response for an editor" do
      get :index, params: {}, format: :js, xhr: true, session: { user_id: editor.id }
      expect(response).to be_successful
    end

    it "returns all events when there is no search term" do
      get :index, params: {}, format: :js, xhr: true, session: { user_id: editor.id }
      expect(assigns(:events).matches).to match_array([sligo, ennis])
    end

    it "filters events by name" do
      get :index, params: { name: "Sligo" }, format: :js, xhr: true, session: { user_id: editor.id }
      expect(assigns(:events).matches).to eq([sligo])
    end

    it "denies access to a guest" do
      get :index, params: {}, format: :js, xhr: true, session: {}
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
