require 'rails_helper'

describe Result do
  let(:user) {FactoryGirl.create :user}

  context "normal reporter" do
    it "can't create Result" do
      result = Result.new(reporter: user)
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
