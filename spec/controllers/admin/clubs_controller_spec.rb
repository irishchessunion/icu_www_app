# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ClubsController, type: :controller do
  let(:admin_user) { create(:user, roles: 'admin') }
  let(:valid_session) { {user_id: admin_user.id} }
  let(:club) { create(:club) }

  describe "GET #edit" do
    context "when user is an admin" do
      it "returns a successful response" do
        get :edit, params: { id: club.to_param }, session: valid_session
        expect(response).to be_successful
      end

      it "assigns the requested club to @club" do
        get :edit, params: { id: club.to_param }, session: valid_session
        expect(assigns(:club)).to eq(club)
      end
    end
  end

  describe "PATCH/PUT #update" do
    context "when user is an admin" do
      context "with valid parameters" do
        let(:valid_attributes) do
          {
            name: "Updated Club Name",
            address: "123 Updated Street",
            eircode: "D02 XY45"
          }
        end

        it "updates the club" do
          patch :update, params: { id: club.id, club: valid_attributes }, session: valid_session
          club.reload
          expect(club.name).to eq("Updated Club Name")
          expect(club.address).to eq("123 Updated Street")
          expect(club.eircode).to eq("D02 XY45")
        end

        it "redirects to the club" do
          patch :update, params: { id: club.id, club: valid_attributes }, session: valid_session
          expect(response).to redirect_to(club_path(club))
        end

        it "sets a success flash message" do
          patch :update, params: { id: club.id, club: valid_attributes }, session: valid_session
          expect(flash[:notice]).to be_present
        end
      end
    end
  end
end