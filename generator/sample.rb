module OASDB
  module Generator
    class Sample
      attr_accessor :oas_seed, :oas_seed_basename, :raffled_antipatterns, :base_resource, :contents, :annotation, :options

      def initialize(oas_seed, oas_seed_basename, raffled_antipatterns, opts = {})
        @oas_seed = oas_seed
        @oas_seed_basename = oas_seed_basename
        @raffled_antipatterns = raffled_antipatterns
        @base_resource = oas_seed['components']['schemas'].slice(oas_seed['components']['schemas'].keys.first)
        @options = opts

        @contents = {}
        contents['openapi'] = '3.0.3'
        contents['info'] = oas_seed['info']
        generate_servers
        contents['components'] = oas_seed['components']
        contents['paths'] = {}
        generate_ids
        generate_id_params

        @annotation = OASDB::Generator::Annotation.new
      end

      def base_resource_name
        base_resource.keys.first
      end

      def base_resource_pretty_name
        base_resource_name.downcase
      end

      def base_resource_example
        base_resource[base_resource_name]['example']
      end

      def basename
        if options['generated_files_basename'].present?
          options['generated_files_basename']
        else
          "g_#{oas_seed_basename}_#{md5}"
        end
      end

      def basename_with_ext
        if options['generated_files_basename'].present?
          "#{options['generated_files_basename']}.json"
        else
          "g_#{oas_seed_basename}_#{md5}.json"
        end
      end

      def resource_id_name(resource_name, style)
        style = :camelcase unless [:camelcase, :underscore].include?(style)
        "#{resource_name}Id".send(style)
      end

      def raw
        JSON.dump(contents)
      end

      def md5
        Digest::MD5.hexdigest(raw)
      end

      private

      def generate_servers
        contents['servers'] = [
          {
            'url': options['mock_api_server_url']
          }
        ]
      end

      def generate_ids
        contents['components']['schemas']['Id'] = {
          'description' => 'A generic integer ID.',
          'type' => 'integer',
          'format' => 'int64'
        }
      end

      def generate_id_params
        contents['components']['parameters'] ||= {}
        contents['components']['parameters'][resource_id_name(base_resource_name, :camelcase)] = {
          'name' => resource_id_name(base_resource_name, :underscore),
          'description' => "The id of a #{base_resource_pretty_name}",
          'in' => 'path',
          'required' => true,
          'schema' => {
            '$ref' => '#/components/schemas/Id'
          }
        }
      end
    end
  end
end
