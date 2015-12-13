require "rails_helper"

RSpec.describe Admin::StatisticsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/admin/statistics").to route_to("admin/statistics#index")
    end

  end
end
