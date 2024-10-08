require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe Admin::SponsorsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Sponsor. As you add validations to Sponsor, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    {name: 'Google', weblink: 'http://google.ie', weight: 100, contact_email: 'bloke@gmail.com', contact_name: 'Some Bloke', valid_until: 1.year.from_now, notes: 'Just a test'}
  }

  let(:invalid_attributes) {
    {name: '', weblink: 'http://google.ie', weight: 100, contact_email: 'bloke no email', contact_name: 'Some Bloke', valid_until: 1.year.ago, notes: 'Just a test'}
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # SponsorsController. Be sure to keep this updated too.
  let(:user) { create(:user, roles: 'treasurer') }
  let(:valid_session) { {user_id: user.id} }

  describe "GET #show" do
    it "assigns the requested sponsor as @sponsor" do
      sponsor = Sponsor.create! valid_attributes
      get :show, params: {:id => sponsor.to_param}, session: valid_session
      expect(assigns(:sponsor)).to eq(sponsor)
    end
  end

  describe "GET #new" do
    it "assigns a new sponsor as @sponsor" do
      get :new, params: {}, session: valid_session
      expect(assigns(:sponsor)).to be_a_new(Sponsor)
    end
  end

  describe "GET #edit" do
    it "assigns the requested sponsor as @sponsor" do
      sponsor = Sponsor.create! valid_attributes
      get :edit, params: {:id => sponsor.to_param}, session: valid_session
      expect(assigns(:sponsor)).to eq(sponsor)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Sponsor" do
        expect {
          post :create, params: {:sponsor => valid_attributes}, session: valid_session
        }.to change(Sponsor, :count).by(1)
      end

      it "assigns a newly created sponsor as @sponsor" do
        post :create, params: {:sponsor => valid_attributes}, session: valid_session
        expect(assigns(:sponsor)).to be_a(Sponsor)
        expect(assigns(:sponsor)).to be_persisted
      end

      it "redirects to the created sponsor" do
        post :create, params: {:sponsor => valid_attributes}, session: valid_session
        expect(response).to redirect_to([:admin, Sponsor.last])
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved sponsor as @sponsor" do
        post :create, params: {:sponsor => invalid_attributes}, session: valid_session
        expect(assigns(:sponsor)).to be_a_new(Sponsor)
      end

      it "re-renders the 'new' template" do
        post :create, params: {:sponsor => invalid_attributes}, session: valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {name: 'Google', weblink: 'http://google.ie', weight: 200, contact_email: 'another_bloke@gmail.com', contact_name: 'Another Bloke', valid_until: 1.year.from_now, notes: 'Just a test'}
      }

      it "updates the requested sponsor" do
        sponsor = Sponsor.create! valid_attributes
        put :update, params: {:id => sponsor.to_param, :sponsor => new_attributes}, session: valid_session
        sponsor.reload
        expect(sponsor.weight).to eq(200)
        expect(sponsor.contact_email).to eq('another_bloke@gmail.com')
        expect(sponsor.contact_name).to eq('Another Bloke')
      end

      it "assigns the requested sponsor as @sponsor" do
        sponsor = Sponsor.create! valid_attributes
        put :update, params: {:id => sponsor.to_param, :sponsor => valid_attributes}, session: valid_session
        expect(assigns(:sponsor)).to eq(sponsor)
      end

      it "redirects to the sponsor" do
        sponsor = Sponsor.create! valid_attributes
        put :update, params: {:id => sponsor.to_param, :sponsor => valid_attributes}, session: valid_session
        expect(response).to redirect_to([:admin, sponsor])
      end
    end

    context "with invalid params" do
      it "assigns the sponsor as @sponsor" do
        sponsor = Sponsor.create! valid_attributes
        put :update, params: {:id => sponsor.to_param, :sponsor => invalid_attributes}, session: valid_session
        expect(assigns(:sponsor)).to eq(sponsor)
      end

      it "re-renders the 'edit' template" do
        sponsor = Sponsor.create! valid_attributes
        put :update, params: {:id => sponsor.to_param, :sponsor => invalid_attributes}, session: valid_session
        expect(response).to render_template("edit")
      end
    end
  end
end
