# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ImageIdsController, type: :controller do
  let(:editor)   { create(:user, roles: 'editor') }
  let!(:image1)  { create(:image) }
  let!(:image2)  { create(:image_april) }

  describe "GET #index" do
    it "returns a successful response for an editor" do
      get :index, params: {}, format: :js, xhr: true, session: { user_id: editor.id }
      expect(response).to be_successful
    end

    it "returns all images when there is no search term" do
      get :index, params: {}, format: :js, xhr: true, session: { user_id: editor.id }
      expect(assigns(:images).matches).to match_array([image1, image2])
    end

    it "filters images by caption" do
      get :index, params: { caption: image2.caption }, format: :js, xhr: true, session: { user_id: editor.id }
      expect(assigns(:images).matches).to eq([image2])
    end

    it "denies access to a guest" do
      get :index, params: {}, format: :js, xhr: true, session: {}
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
