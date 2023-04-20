namespace :load do
  task :defaults do
    set :precompile_env,   'production'
    set :packs_dir,        "public/packs"
    set :rsync_cmd,        "rsync -av --delete"
    set :assets_role,      "web"

    after "bundler:install", "deploy:assets:prepare"
    after "deploy:assets:prepare", "deploy:assets:rsync"
    after "deploy:assets:rsync", "deploy:assets:cleanup"
  end
end

namespace :deploy do
  namespace :assets do
    desc "Remove all local precompiled assets"
    task :cleanup do
      run_locally do
        with rails_env: fetch(:precompile_env) do
          execute "rm", "-rf", fetch(:packs_dir)
        end
      end
    end

    desc "Actually precompile the assets locally"
    task :prepare do
      run_locally do
        execute "bundle exec rake webpacker:clobber NODE_ENV=#{fetch(:precompile_env)}"
        execute "bundle exec rake webpacker:compile NODE_ENV=#{fetch(:precompile_env)}"
      end
    end

    desc "Performs rsync to app servers"
    task :rsync do
      on roles(fetch(:assets_role)), in: :parallel do |server|
        run_locally do
          execute "#{fetch(:rsync_cmd)} ./#{fetch(:packs_dir)}/ #{server.user}@#{server.hostname}:#{release_path}/#{fetch(:packs_dir)}/" if Dir.exists?(fetch(:packs_dir))
        end
      end
    end
  end
end
