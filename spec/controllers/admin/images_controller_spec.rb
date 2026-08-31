# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ImagesController, type: :controller do
  render_views

  let(:editor) { create(:user, roles: 'editor') }
  let(:valid_session) { { user_id: editor.id } }
  let(:valid_attributes) do
    {
      data: fixture_file_upload("#{Rails.root}/spec/files/images/fractal.jpg", "image/jpeg"),
      caption: "A fractal",
      credit: "Mark Orr",
      year: 2020
    }
  end

  describe "POST #create" do
    context "format: js (used by the article editor's image picker)" do
      it "creates the image and renders the callback JS on success" do
        post :create, params: { image: valid_attributes }, format: :js, session: valid_session
        expect(response).to be_successful
        expect(Image.count).to eq(1)
        expect(response.body).to include("image_ids_callback(#{Image.last.id}")
      end

      it "re-renders the upload form on failure without creating an image" do
        post :create, params: { image: valid_attributes.merge(caption: "") }, format: :js, session: valid_session
        expect(response).to be_successful
        expect(Image.count).to eq(0)
        expect(response.body).to include("image_ids_upload_form_wrapper")
      end
    end

    context "format: html (the normal admin flow)" do
      it "redirects to the image on success" do
        post :create, params: { image: valid_attributes }, session: valid_session
        expect(response).to redirect_to(Image.last)
      end
    end
  end
end
