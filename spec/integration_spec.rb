require 'spec_helper'

describe Capistrano::LocalPrecompile, "integration" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.load do
      def precompile_env; 'production'; end
      def rake; 'rake'; end
    end
    Capistrano::LocalPrecompile.load_into(@configuration)
  end

  describe 'cleanup task' do
    it 'removes the asset files from public/assets' do
      expect(@configuration).to receive(:run_locally).
        with('rm -rf public/packs')

      @configuration.find_and_execute_task('deploy:assets:cleanup')
    end
  end

  describe 'prepare task' do
    it 'invokes the precompile command' do
      expect(@configuration).to receive(:run_locally).
        with('NODE_ENV=production rake webpacker:compile').once

      @configuration.find_and_execute_task('deploy:assets:prepare')
    end
  end


  describe 'precompile task' do
    let(:servers) { %w(10.0.1.1 10.0.1.2) }

    before do
      allow(@configuration).to receive(:run_locally).
        with('NODE_ENV=production rake webpacker:compile').once
      allow(@configuration).to receive(:run_locally).
        with('rm -rf public/packs').once


      allow(@configuration).to receive(:user).and_return('root')
      allow(@configuration).to receive(:assets_role).and_return('app')
      allow(@configuration).to receive(:find_servers).and_return(servers)
      allow(@configuration).to receive(:release_path).and_return('/tmp')
    end

    it 'rsyncs the local asset files to the server' do
      expect(@configuration).to receive(:run_locally).with(/rsync -av/).exactly(4).times

      @configuration.find_and_execute_task('deploy:assets:precompile')
    end
  end
end
