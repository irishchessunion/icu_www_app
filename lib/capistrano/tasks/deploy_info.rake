namespace :deploy do
  desc "Write deploy metadata to DEPLOY_INFO in the release directory"
  task :write_deploy_info do
    on roles(:app) do
      within release_path do
        branch = fetch(:branch).to_s
        commit = capture(:git, "rev-parse HEAD").strip
        tag = capture(:git, "describe --tags --exact-match 2>/dev/null || true").strip
        message = capture(:git, "log -1 --pretty=%s").strip
        deployed_at = capture(:date, "-u +%Y-%m-%dT%H:%M:%SZ").strip

        execute :bash, "-lc", <<~BASH
          cat > #{release_path.join("DEPLOY_INFO")} <<'EOF'
          deployed_at=#{deployed_at}
          branch=#{branch}
          tag=#{tag}
          commit=#{commit}
          message=#{message}
          EOF
        BASH
      end
    end
  end
end

after "deploy:updating", "deploy:write_deploy_info"
