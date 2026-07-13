namespace :deploy do
  desc "Write deploy metadata to DEPLOY_INFO in the release directory"
  task :write_deploy_info do
    on roles(:app) do
      commit = capture(:cat, release_path.join("REVISION")).strip
      branch = fetch(:branch).to_s
      tag = capture(:git, "--git-dir", repo_path.to_s, "describe --tags --exact-match", commit, "2>/dev/null || true").strip
      message = capture(:git, "--git-dir", repo_path.to_s, "log -1 --pretty=%s", commit).strip
      deployed_at = capture(:date, "-u +%Y-%m-%dT%H:%M:%SZ").strip

      info = <<~INFO
        deployed_at=#{deployed_at}
        branch=#{branch}
        tag=#{tag}
        commit=#{commit}
        message=#{message}
      INFO

      upload! StringIO.new(info), release_path.join("DEPLOY_INFO").to_s
    end
  end
end

after "deploy:updating", "deploy:write_deploy_info"