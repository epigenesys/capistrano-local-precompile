require "tempfile"
require "yaml"

module Capistrano
  module LocalPrecompile
    class ShakapackerConfig
      def self.create(config_path, local_environment, precompile_environment)
        config = load(config_path)
        config.fetch(precompile_environment) do
          raise "Shakapacker configuration does not define #{precompile_environment.inspect}"
        end
        config[local_environment] = config[precompile_environment]

        temporary_config = Tempfile.new(["shakapacker-", ".yml"])
        temporary_config.write(YAML.dump(config))
        temporary_config.close
        temporary_config
      end

      def self.load(config_path)
        YAML.load_file(config_path, aliases: true)
      rescue ArgumentError
        YAML.load_file(config_path)
      end
      private_class_method :load
    end
  end
end
