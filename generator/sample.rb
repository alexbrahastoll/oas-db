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

        @annotation = OASDB::Generator::Annotation.new
      end

      def base_resource_name
        base_resource.keys.first
      end

      def base_resource_pretty_name
        base_resource_name.downcase
      end

      def basename
        "g_#{oas_seed_basename}_#{md5}.json"
      end

      def raw
        JSON.dump(contents)
      end

      def md5
        Digest::MD5.hexdigest(raw)
      end
    end
  end
end
