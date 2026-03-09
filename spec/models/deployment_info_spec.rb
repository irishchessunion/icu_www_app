RSpec.describe DeploymentInfo, type: :model do
  describe ".current" do
    it "loads branch, tag and commit from git when neither file exists" do
      allow(File).to receive(:exist?).with(described_class::DEPLOY_INFO_FILE).and_return(false)
      allow(File).to receive(:exist?).with(described_class::REVISION_FILE).and_return(false)

      allow(IO).to receive(:popen)
                     .with(["git", "rev-parse", "--abbrev-ref", "HEAD"], err: File::NULL)
                     .and_yield(double(read: "main\n"))

      allow(IO).to receive(:popen)
                     .with(["git", "describe", "--tags", "--exact-match"], err: File::NULL)
                     .and_yield(double(read: "v1.2.3\n"))

      allow(IO).to receive(:popen)
                     .with(["git", "rev-parse", "HEAD"], err: File::NULL)
                     .and_yield(double(read: "abcdef1234567890abcdef1234567890abcdef12\n"))

      allow(IO).to receive(:popen)
                     .with(["git", "log", "-1", "--pretty=%s"], err: File::NULL)
                     .and_yield(double(read: "Add deployment info page\n"))

      deployment_info = described_class.current

      expect(deployment_info.deployed_at).to be_nil
      expect(deployment_info.booted_at).to eq(APP_BOOTED_AT)
      expect(deployment_info.branch).to eq("main")
      expect(deployment_info.tag).to eq("v1.2.3")
      expect(deployment_info.commit).to eq("abcdef1234567890abcdef1234567890abcdef12")
      expect(deployment_info.message).to eq("Add deployment info page")
    end

    it "loads deployed_at, branch, tag and commit from the deploy info file when it exists" do
      allow(File).to receive(:exist?).with(described_class::DEPLOY_INFO_FILE).and_return(true)
      allow(File).to receive(:readlines).with(described_class::DEPLOY_INFO_FILE, chomp: true)
                                        .and_return([
                     "deployed_at=2026-03-08T12:34:56Z",
                     "branch=main",
                     "tag=v1.2.3",
                     "commit=abcdef1234567890abcdef1234567890abcdef12",
                     "message=Add deployment info page"
                                                    ])

      expect(IO).not_to receive(:popen)

      deployment_info = described_class.current

      expect(deployment_info.deployed_at).to eq(Time.zone.parse("2026-03-08T12:34:56Z"))
      expect(deployment_info.booted_at).to eq(APP_BOOTED_AT)
      expect(deployment_info.branch).to eq("main")
      expect(deployment_info.tag).to eq("v1.2.3")
      expect(deployment_info.commit).to eq("abcdef1234567890abcdef1234567890abcdef12")
      expect(deployment_info.message).to eq("Add deployment info page")
    end

    it "loads the commit from REVISION when DEPLOY_INFO does not exist" do
      allow(File).to receive(:exist?).with(described_class::DEPLOY_INFO_FILE).and_return(false)
      allow(File).to receive(:exist?).with(described_class::REVISION_FILE).and_return(true)
      allow(File).to receive(:read).with(described_class::REVISION_FILE).and_return("abcdef1234567890abcdef1234567890abcdef12\n")

      expect(IO).not_to receive(:popen)

      deployment_info = described_class.current

      expect(deployment_info.deployed_at).to be_nil
      expect(deployment_info.booted_at).to eq(APP_BOOTED_AT)
      expect(deployment_info.branch).to be_nil
      expect(deployment_info.tag).to be_nil
      expect(deployment_info.commit).to eq("abcdef1234567890abcdef1234567890abcdef12")
      expect(deployment_info.message).to be_nil
    end

  end
end