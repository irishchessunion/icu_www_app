namespace :deploy do
  desc "Write deploy metadata to DEPLOY_INFO in the release directory"
  task :write_deploy_info do
    branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
    tag = `git describe --tags --exact-match 2>/dev/null`.strip
    message = `git log -1 --pretty=%s 2>/dev/null`.strip
    on roles(:app) do
      within release_path do
        commit = capture(:cat, "REVISION").strip
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
