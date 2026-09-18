require "shellwords"
require_relative "local_precompile/shakapacker_config"

namespace :load do
  task :defaults do
    set :precompile_env,   'production'
    set :shakapacker_config, "config/shakapacker.yml"
    set :shakapacker_config_environment, "development"
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
        precompile_env = fetch(:precompile_env).to_s
        config_environment = fetch(:shakapacker_config_environment).to_s
        temporary_config = Capistrano::LocalPrecompile::ShakapackerConfig.create(
          fetch(:shakapacker_config), config_environment, precompile_env
        )
        begin
          config_path = Shellwords.shellescape(temporary_config.path)
          node_env = Shellwords.shellescape(precompile_env)
          command_prefix = "SHAKAPACKER_CONFIG=#{config_path}"

          execute "#{command_prefix} bundle exec rake shakapacker:clobber NODE_ENV=#{node_env}"
          execute "#{command_prefix} bundle exec rake shakapacker:compile NODE_ENV=#{node_env}"
        ensure
          temporary_config.close
          temporary_config.unlink
        end
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
