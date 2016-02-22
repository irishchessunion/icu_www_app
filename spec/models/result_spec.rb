require 'rails_helper'

describe Result do
  let(:user) {FactoryGirl.create :user}

  context "normal reporter" do
    it "can create Result" do
      result = Result.new(reporter: user, competition: 'ARM', player1: 'JOC', player2: 'GMacE', score: '1-0')
      expect(result.valid?).to eq true
    end

    it "banning deactivates the result" do
      result = Result.create(reporter: user, message: 'some result')
      result.ban
      expect(result.active?).to be_falsey
      expect(user.disallow_reporting?).to eq true
    end
  end
end
