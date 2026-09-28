require_relative "local_precompile/shakapacker_config"

namespace :load do
  task :defaults do
    set :precompile_env,   'production'
    set :assets_pipeline_enabled, false
    set :shakapacker_enabled, true
    set :shakapacker_config, "config/shakapacker.yml"
    set :shakapacker_config_environment, "development"
    set :assets_dir,       "public/assets"
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
        execute "rm", "-rf", fetch(:assets_dir)
        execute "rm", "-rf", fetch(:packs_dir)
      end
    end

    desc "Actually precompile the assets locally"
    task :prepare do
      run_locally do
        precompile_env = fetch(:precompile_env).to_s
        assets_pipeline_enabled = fetch(:assets_pipeline_enabled)
        shakapacker_enabled = fetch(:shakapacker_enabled)
        temporary_config = nil

        if shakapacker_enabled
          temporary_config = Capistrano::LocalPrecompile::ShakapackerConfig.create(
            fetch(:shakapacker_config), fetch(:shakapacker_config_environment).to_s, precompile_env
          )
          shakapacker_environment = "SHAKAPACKER_CONFIG=#{temporary_config.path} NODE_ENV=#{precompile_env}"
        end

        if assets_pipeline_enabled
          assets_environment = "RAILS_ENV=#{precompile_env}"
          assets_environment = "#{shakapacker_environment} SHAKAPACKER_PRECOMPILE=true #{assets_environment}" if shakapacker_enabled

          execute "#{assets_environment} bundle exec rake assets:clobber"
          execute "#{assets_environment} MINIFY_ASSETS=true bundle exec rake assets:precompile"
        elsif shakapacker_enabled
          execute "#{shakapacker_environment} bundle exec rake shakapacker:clobber"
          execute "#{shakapacker_environment} bundle exec rake shakapacker:compile"
        end
      ensure
        temporary_config.close! if temporary_config
      end
    end

    desc "Performs rsync to app servers"
    task :rsync do
      on roles(fetch(:assets_role)), in: :parallel do |server|
        run_locally do
          execute "#{fetch(:rsync_cmd)} ./#{fetch(:assets_dir)}/ #{server.user}@#{server.hostname}:#{release_path}/#{fetch(:assets_dir)}/" if Dir.exist?(fetch(:assets_dir))
          execute "#{fetch(:rsync_cmd)} ./#{fetch(:packs_dir)}/ #{server.user}@#{server.hostname}:#{release_path}/#{fetch(:packs_dir)}/" if Dir.exist?(fetch(:packs_dir))
        end
      end
    end
  end
end
