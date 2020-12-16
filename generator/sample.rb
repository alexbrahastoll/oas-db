module OASDB
  module Generator
    class Sample
      attr_accessor :oas_seed, :oas_seed_basename, :raffled_antipatterns, :base_resource, :contents, :annotation

      def initialize(oas_seed, oas_seed_basename, raffled_antipatterns)
        @oas_seed = oas_seed
        @oas_seed_basename = oas_seed_basename
        @raffled_antipatterns = raffled_antipatterns
        @base_resource = oas_seed['components']['schemas'].slice(oas_seed['components']['schemas'].keys.first)

        @contents = {}
        contents['info'] = oas_seed['info']
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

      def basename
        "g_#{oas_seed_basename}_#{md5}"
      end

      def basename_with_ext
        "g_#{oas_seed_basename}_#{md5}.json"
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
