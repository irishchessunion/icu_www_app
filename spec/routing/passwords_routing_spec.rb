require "rails_helper"

RSpec.describe PasswordsController, type: :routing do
  describe "routing" do

    it "routes to #new" do
      expect(:get => "/password/new").to route_to("passwords#new")
    end

    it "routes to #edit" do
      expect(:get => "/password/edit").to route_to("passwords#edit")
    end

    it "routes to #create" do
      expect(:post => "/password").to route_to("passwords#create")
    end

    it "routes to #update" do
      expect(:put => "/password").to route_to("passwords#update")
    end
  end
end
