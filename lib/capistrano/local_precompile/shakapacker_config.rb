require "tempfile"
require "yaml"

module Capistrano
  module LocalPrecompile
    class ShakapackerConfig
      def self.create(config_path, local_environment, node_environment)
        config = load(config_path)
        config.fetch(node_environment) do
          raise "Shakapacker configuration does not define #{node_environment.inspect}"
        end
        config[local_environment] = config[node_environment]

        temporary_config = Tempfile.new(["shakapacker-", ".yml"])
        temporary_config.write(YAML.dump(config))
        temporary_config.close
        temporary_config
      end

      def self.load(config_path)
        if YAML.respond_to?(:safe_load_file)
          YAML.safe_load_file(config_path, aliases: true)
        else
          YAML.load_file(config_path)
        end
      end
      private_class_method :load
    end
  end
end
