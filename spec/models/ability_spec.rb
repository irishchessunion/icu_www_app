require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  context Player do
    let(:player) { create(:player) }
    let(:ability) { Ability.new(user) }

    context "user" do
      let(:user) { create(:user) }

      it "can only view own player" do
        expect(ability.can?(:show, user.player)).to be true
        expect(ability.can?(:show, player)).to be false
      end
    end
  end

  context User do

    it "can report results" do
      expect(Ability.new(User.new).can?(:create, Result)).to be true
    end

    it "can't report results if reporting disallowed" do
      expect(Ability.new(User.new(disallow_reporting: true)).can?(:create, Result)).to be false
    end

  end

  context "Event permissions" do
    let(:creator) { create(:user, roles: "organiser") }
    let(:full_user) { create(:user, roles: "organiser") }
    let(:limited_user) { create(:user, roles: "organiser") }
    let(:other_user) { create(:user) }
    let(:event) { create(:event, user: creator) }

    before do
      create(:event_user, event: event, user: full_user, role: "full_access")
      create(:event_user, event: event, user: limited_user, role: "limited_access")
    end

    context "creator" do
      let(:ability) { Ability.new(creator) }

      it "can manage their own event" do
        expect(ability.can?(:manage, event)).to be true
      end

      it "can manage event_users for their event" do
        event_user = create(:event_user, event: event)
        expect(ability.can?(:create, event_user)).to be true
        expect(ability.can?(:destroy, event_user)).to be true
      end
    end

    context "full_access user" do
      let(:ability) { Ability.new(full_user) }

      it "can read and update event" do
        expect(ability.can?(:read, event)).to be true
        expect(ability.can?(:update, event)).to be true
      end

      it "cannot destroy event" do
        expect(ability.can?(:destroy, event)).to be false
      end

      it "cannot manage event_users" do
        event_user = create(:event_user, event: event)
        expect(ability.can?(:create, event_user)).to be false
        expect(ability.can?(:destroy, event_user)).to be false
      end
    end

    context "limited_access user" do
      let(:ability) { Ability.new(limited_user) }

      it "can only read event" do
        expect(ability.can?(:read, event)).to be true
        expect(ability.can?(:show, event)).to be true
        expect(ability.can?(:update, event)).to be false
        expect(ability.can?(:destroy, event)).to be false
      end
    end

    context "editor role" do
      let(:editor) { create(:user, roles: "editor") }
      let(:editor_event) { create(:event, user: editor) }
      let(:ability) { Ability.new(editor) }

      it "has same event permissions as organiser" do
        expect(ability.can?(:manage, editor_event)).to be true
        expect(ability.can?(:index, Event)).to be true
      end

      it "cannot manage fees or items" do
        entry_fee = create(:entry_fee, event: editor_event)
        expect(ability.can?(:manage, entry_fee)).to be false
      end
    end
  end
end
