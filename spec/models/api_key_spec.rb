require 'rails_helper'

describe ApiKey do
  context "key" do
    let(:api_key) { create(:api_key) }

    it "is generated on creation" do
      expect(api_key.key).to match(/\A[0-9a-f]{64}\z/)
      expect(api_key.key_prefix).to eq api_key.key.first(8)
    end

    it "is different each time" do
      expect(create(:api_key).key).to_not eq api_key.key
    end

    it "is only stored as a digest" do
      expect(api_key.key_digest).to eq Digest::SHA256.hexdigest(api_key.key)
      expect(api_key.attributes.values).to_not include api_key.key
      expect(ApiKey.find(api_key.id).key).to be_nil
    end

    it "doesn't change when the record is updated" do
      digest = api_key.key_digest
      api_key.update!(name: "Renamed")
      expect(api_key.reload.key_digest).to eq digest
    end
  end

  context "name" do
    it "is required" do
      expect(build(:api_key, name: " ")).to_not be_valid
    end

    it "is unique" do
      create(:api_key, name: "Chess Results")
      expect(build(:api_key, name: "Chess Results")).to_not be_valid
    end

    it "is tidied" do
      expect(create(:api_key, name: "  Chess   Results ").name).to eq "Chess Results"
    end
  end

  context "authenticate" do
    let!(:api_key) { create(:api_key) }

    it "finds the key" do
      expect(ApiKey.authenticate(api_key.key)).to eq api_key
    end

    it "rejects a wrong, blank or missing key" do
      expect(ApiKey.authenticate("x" * 64)).to be_nil
      expect(ApiKey.authenticate("")).to be_nil
      expect(ApiKey.authenticate(nil)).to be_nil
    end

    it "rejects an inactive key" do
      api_key.update!(active: false)
      expect(ApiKey.authenticate(api_key.key)).to be_nil
    end

    it "rejects the digest" do
      expect(ApiKey.authenticate(api_key.key_digest)).to be_nil
    end
  end

  context "permissions" do
    it "can be set from an array or a string" do
      expect(build(:api_key, permissions: ["events"]).permissions).to eq "events"
      expect(build(:api_key, permissions: "events").permissions).to eq "events"
    end

    it "are nil when there are none" do
      expect(build(:api_key, permissions: [""]).permissions).to be_nil
      expect(build(:api_key, permissions: nil).permissions).to be_nil
    end

    it "ignore anything unknown" do
      api_key = build(:api_key, permissions: %w[events everything])
      expect(api_key.permission_names).to eq %w[events]
    end

    it "say what the key permits" do
      expect(build(:api_key, permissions: "events").permits?("events")).to eq true
      expect(build(:api_key, permissions: nil).permits?("events")).to eq false
    end

    it "have names" do
      expect(build(:api_key, permissions: "events").human_permissions).to eq "Access Events"
    end
  end
end
