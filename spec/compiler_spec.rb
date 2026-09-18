require "spec_helper"
require "tmpdir"
require "yaml"

require "capistrano/local_precompile/compiler"

describe Capistrano::LocalPrecompile::Compiler do
  class CommandRunner
    attr_reader :commands

    def initialize
      @commands = []
    end

    def execute(command)
      @commands << command
    end
  end

  def compiler_for(config_path, assets_pipeline_enabled: false, shakapacker_enabled: true)
    command_runner = CommandRunner.new
    compiler = described_class.new(
      command_runner,
      precompile_env: "production",
      shakapacker_config: config_path,
      shakapacker_config_environment: "development",
      assets_pipeline_enabled: assets_pipeline_enabled,
      shakapacker_enabled: shakapacker_enabled
    )
    [compiler, command_runner]
  end

  def write_shakapacker_config(directory)
    config_path = File.join(directory, "shakapacker.yml")
    File.write(config_path, <<~YAML)
      development:
        compile: true
      production:
        compile: false
    YAML
    config_path
  end

  it "compiles only the Rails asset pipeline when enabled" do
    Dir.mktmpdir do |directory|
      compiler, command_runner = compiler_for(
        write_shakapacker_config(directory), assets_pipeline_enabled: true, shakapacker_enabled: false
      )

      compiler.compile

      expect(command_runner.commands).to eq([
        "RAILS_ENV=production bundle exec rake assets:clobber",
        "RAILS_ENV=production MINIFY_ASSETS=true bundle exec rake assets:precompile"
      ])
    end
  end

  it "compiles only Shakapacker when enabled" do
    Dir.mktmpdir do |directory|
      compiler, command_runner = compiler_for(write_shakapacker_config(directory))

      compiler.compile

      expect(command_runner.commands).to match([
        /\ASHAKAPACKER_CONFIG=.* NODE_ENV=production bundle exec rake shakapacker:clobber\z/,
        /\ASHAKAPACKER_CONFIG=.* NODE_ENV=production bundle exec rake shakapacker:compile\z/
      ])
    end
  end

  it "compiles both pipelines through the Rails asset task" do
    Dir.mktmpdir do |directory|
      compiler, command_runner = compiler_for(
        write_shakapacker_config(directory), assets_pipeline_enabled: true
      )

      compiler.compile

      expect(command_runner.commands).to match([
        /\ASHAKAPACKER_CONFIG=.* NODE_ENV=production SHAKAPACKER_PRECOMPILE=true RAILS_ENV=production bundle exec rake assets:clobber\z/,
        /\ASHAKAPACKER_CONFIG=.* NODE_ENV=production SHAKAPACKER_PRECOMPILE=true RAILS_ENV=production MINIFY_ASSETS=true bundle exec rake assets:precompile\z/
      ])
    end
  end

  it "does not compile assets when both pipelines are disabled" do
    Dir.mktmpdir do |directory|
      compiler, command_runner = compiler_for(
        write_shakapacker_config(directory), shakapacker_enabled: false
      )

      compiler.compile

      expect(command_runner.commands).to be_empty
    end
  end
end
