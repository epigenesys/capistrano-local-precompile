require "shellwords"
require_relative "shakapacker_config"

module Capistrano
  module LocalPrecompile
    class Compiler
      def initialize(command_runner, precompile_env:, shakapacker_config:, shakapacker_config_environment:,
                     assets_pipeline_enabled:, shakapacker_enabled:)
        @command_runner = command_runner
        @precompile_env = precompile_env.to_s
        @shakapacker_config = shakapacker_config
        @shakapacker_config_environment = shakapacker_config_environment.to_s
        @assets_pipeline_enabled = assets_pipeline_enabled
        @shakapacker_enabled = shakapacker_enabled
      end

      def compile
        if @assets_pipeline_enabled && @shakapacker_enabled
          with_shakapacker_config { |environment| compile_assets(environment) }
        elsif @assets_pipeline_enabled
          compile_assets
        elsif @shakapacker_enabled
          with_shakapacker_config { |environment| compile_shakapacker(environment) }
        end
      end

      private

      def compile_assets(shakapacker_environment = nil)
        rails_env = Shellwords.shellescape(@precompile_env)
        environment = "RAILS_ENV=#{rails_env}"
        environment = "#{shakapacker_environment} SHAKAPACKER_PRECOMPILE=true #{environment}" if shakapacker_environment

        @command_runner.execute "#{environment} bundle exec rake assets:clobber"
        @command_runner.execute "#{environment} MINIFY_ASSETS=true bundle exec rake assets:precompile"
      end

      def compile_shakapacker(environment)
        @command_runner.execute "#{environment} bundle exec rake shakapacker:clobber"
        @command_runner.execute "#{environment} bundle exec rake shakapacker:compile"
      end

      def with_shakapacker_config
        temporary_config = ShakapackerConfig.create(
          @shakapacker_config, @shakapacker_config_environment, @precompile_env
        )

        begin
          config_path = Shellwords.shellescape(temporary_config.path)
          node_env = Shellwords.shellescape(@precompile_env)
          yield "SHAKAPACKER_CONFIG=#{config_path} NODE_ENV=#{node_env}"
        ensure
          temporary_config.close
          temporary_config.unlink
        end
      end
    end
  end
end
