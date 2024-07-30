namespace :load do
  task :defaults do
    set :precompile_env,   'production'
    set :packs_dir,        "public/packs"
    set :rsync_cmd,        "rsync -av --delete"
    set :assets_role,      "web"

    after "bundler:install", "deploy:assets:prepare"
    after "deploy:assets:prepare", "deploy:assets:rsync"
  end
end

namespace :deploy do
  namespace :assets do
    desc "Actually precompile the assets locally"
    task :prepare do
      run_locally do
        execute "bundle exec rake shakapacker:clobber NODE_ENV=#{fetch(:precompile_env)}"
        execute "bundle exec rake shakapacker:compile NODE_ENV=#{fetch(:precompile_env)}"
      end
    end

    desc "Performs rsync to app servers"
    task :rsync do
      on roles(fetch(:assets_role)), in: :parallel do |server|
        run_locally do
          execute "#{fetch(:rsync_cmd)} ./#{fetch(:packs_dir)}/ #{server.user}@#{server.hostname}:#{release_path}/#{fetch(:packs_dir)}/"
        end
      end
    end
  end
end
