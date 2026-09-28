require "spec_helper"
require "tmpdir"
require "yaml"

require "capistrano/local_precompile/shakapacker_config"

describe Capistrano::LocalPrecompile::ShakapackerConfig do
  describe ".create" do
    it "maps the local Rails environment to the precompile environment" do
      Dir.mktmpdir do |directory|
        config_path = File.join(directory, "shakapacker.yml")
        File.write(config_path, <<~YAML)
          default: &default
            public_output_path: packs
          development:
            <<: *default
            compile: true
          production:
            <<: *default
            compile: false
        YAML

        temporary_config_path = nil
        described_class.create(config_path, "development", "production") do |temporary_config|
          temporary_config_path = temporary_config.path
          copied_config = YAML.load_file(temporary_config_path, aliases: true)
          expect(copied_config.fetch("development")).to eq(copied_config.fetch("production"))
          expect(copied_config.fetch("development").fetch("compile")).to be(false)
        end
        source_config = YAML.load_file(config_path, aliases: true)

        expect(source_config.fetch("development").fetch("compile")).to be(true)
        expect(File).not_to exist(temporary_config_path)
      end
    end

    it "raises when the precompile environment is absent" do
      Dir.mktmpdir do |directory|
        config_path = File.join(directory, "shakapacker.yml")
        File.write(config_path, "development:\n  compile: true\n")

        expect do
          described_class.create(config_path, "development", "production") { nil }
        end.to raise_error("Shakapacker configuration does not define \"production\"")
      end
    end
  end
end
