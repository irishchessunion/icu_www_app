require 'rails_helper'

RSpec.describe LikesController, type: :routing do
  describe 'routing' do

    it 'routes to #create' do
      expect(:post => '/likes?news_id=2').to route_to('likes#create', news_id: '2')
    end

    it 'routes to #destroy' do
      expect(:delete => '/likes/1').to route_to('likes#destroy', id: '1')
    end

  end
end
