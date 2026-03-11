require 'rails_helper'

describe EventUser do
  let(:event) { create(:event) }
  let(:user) { create(:user, roles: "organiser") }

  context "validations" do
    it "requires event_id" do
      event_user = build(:event_user, user: user, event: nil)
      expect(event_user).not_to be_valid
      expect(event_user.errors[:event_id]).to include("can't be blank")
    end

    it "requires user_id" do
      event_user = build(:event_user, event: event, user: nil)
      expect(event_user).not_to be_valid
      expect(event_user.errors[:user_id]).to include("can't be blank")
    end

    it "prevents duplicate event-user combinations" do
      create(:event_user, event: event, user: user)
      duplicate = build(:event_user, event: event, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:event_id]).to include("has already been taken")
    end
  end

  context "scopes" do
    let!(:full_access_user) { create(:event_user, event: event, user: user, role: "full_access") }
    let!(:limited_access_user) { create(:event_user, event: event, user: create(:user), role: "limited_access") }

    it "full_access scope only returs full_access users" do
      expect(EventUser.full_access).to include(full_access_user)
      expect(EventUser.full_access).not_to include(limited_access_user)
    end

    it "limited_access scope only returns limited_access users" do
      expect(EventUser.limited_access).to include(limited_access_user)
      expect(EventUser.limited_access).not_to include(full_access_user)
    end
  end

  context "helper methods" do
    let(:full_user) { create(:event_user, role: "full_access") }
    let(:limited_user) { create(:event_user, role: "limited_access") }

    it "full_access? returns true for full_access role" do
      expect(full_user.full_access?).to be true
      expect(limited_user.full_access?).to be false
    end

    it "limited_access? returns true for limited_access role" do
      expect(limited_user.limited_access?).to be true
      expect(full_user.limited_access?).to be false
    end
  end
end
