require 'json'
require 'digest'
require 'active_support/all'
require_relative 'sample'
require_relative 'create_operation'
require_relative 'read_operation'
require_relative 'update_operation'
require_relative 'delete_operation'
require_relative 'annotation'
require_relative 'api'

module OASDB
  module Generator
    class Engine
      attr_accessor :random, :oas_seed, :oas_seed_basename, :desired_num_samples, :spec_issues, :api_issues,
        :antipatterns, :generated_samples, :generated_apis, :raffled_antipatterns, :options

      HTTP_METHODS = ['get', 'post', 'head', 'put', 'patch', 'delete'].freeze

      def initialize(random_generator_seed, oas_seed_path, desired_num_samples, spec_issues = [], api_issues = [], opts = {})
        @random = Random.new(random_generator_seed)
        @oas_seed = JSON.parse(File.read(oas_seed_path))
        @oas_seed_basename = File.basename(oas_seed_path, '.*')
        @desired_num_samples = desired_num_samples
        # @antipatterns =
        #   JSON.
        #     parse(File.read('meta/antipatterns.json')).
        #     map { |antipattern| antipattern['name'] }
        @antipatterns = ['crudy_uri', 'amorphous_uri', 'ignoring_status_code', 'inappropriate_http_method', 'invalid_examples']
        @spec_issues = spec_issues
        @api_issues = api_issues
        @options = {
          'mock_api_server_url' => 'http://localhost:3000',
          'generated_files_basename' => ''
        }.merge(opts)
      end

      def run
        @generated_samples = []
        @generated_apis = []

        while generated_samples.length < desired_num_samples
          sample, api = generate_sample

          unless generated_samples.map(&:md5).include?(sample.md5)
            generated_samples << sample
            generated_apis << api
          end
        end

        @generated_samples.each_with_index do |s, i|
          sample_path = "samples/#{s.basename_with_ext}"
          s.annotation.annotation_target = sample_path

          File.write(sample_path, s.raw)
          File.write("annotations/#{s.basename_with_ext}", s.annotation.raw)
          File.write("apis/#{s.basename}.rb", generated_apis[i].contents)
        end
      end

      def generate_sample
        antipatterns_num = random.rand(antipatterns.length) + 1 # +1 guarantees a range from 1 to length
        shuffled_antipatterns = antipatterns.shuffle(random: random)
        # @raffled_antipatterns = shuffled_antipatterns.take(antipatterns_num)
        # @raffled_antipatterns = []
        @raffled_antipatterns = spec_issues

        sample = OASDB::Generator::Sample.new(oas_seed, oas_seed_basename, raffled_antipatterns, options)

        oas_create_operation = OASDB::Generator::CreateOperation.new.generate(self, sample)
        oas_read_operation = OASDB::Generator::ReadOperation.new.generate(self, sample)
        oas_update_operation = OASDB::Generator::UpdateOperation.new.generate(self, sample)
        oas_delete_operation = OASDB::Generator::DeleteOperation.new.generate(self, sample)

        sample.contents['paths'].merge!(oas_create_operation)
        sample.contents['paths'].merge!(oas_read_operation)

        update_path = oas_update_operation.keys.first
        if sample.contents['paths'].keys.include?(update_path)
          # In a REST compliant API, many different operations share the same path.
          # Therefore, we have to check if the path of the current operation is already present in order
          # not to override other operations previously added to the specification being built.
          sample.contents['paths'][update_path].merge!(oas_update_operation[update_path])
        else
          sample.contents['paths'].merge!(oas_update_operation)
        end

        delete_path = oas_delete_operation.keys.first
        if sample.contents['paths'].keys.include?(delete_path)
          sample.contents['paths'][delete_path].merge!(oas_delete_operation[delete_path])
        else
          sample.contents['paths'].merge!(oas_delete_operation)
        end

        # selected_api_issues = ['invalid_payload', 'unexpected_payload_root_node', 'payload_missing_keys',
        #   'payload_extra_keys', 'payload_wrong_data_types', 'broken_record_deletion']
        selected_api_issues = api_issues
        selected_api_issues.each { |issue| sample.annotation.add_api_issue(issue) }
        api = OASDB::Generator::API.new(selected_api_issues)
        api.gen_setup_code
        api.gen_code_create_operation(oas_seed, oas_create_operation)
        api.gen_code_read_operation(oas_seed, oas_read_operation)
        api.gen_code_update_operation(oas_seed, oas_update_operation)
        api.gen_code_delete_operation(oas_seed, oas_delete_operation)

        [sample, api]
      end

      def gen_example(sample, breadcrumb)
        return sample.base_resource_example unless raffled_antipatterns.include?('invalid_examples')

        sample.annotation.add_antipattern('invalid_examples', breadcrumb)
        sample.base_resource_example.deep_dup.slice(sample.base_resource_example.keys.first)
      end

      def gen_response_code(sample, correct_code, breadcrumb)
        return correct_code.to_s unless raffled_antipatterns.include?('ignoring_status_code')

        raffled_code =
          if correct_code >= 200 && correct_code <= 299
            [200, 201, 202, 203, 204, 205, 206, 207, 208, 226].
              reject { |code| code == correct_code }.
              sample(random: random)
          elsif correct_code >= 400 && correct_code <= 499
            [400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422,
              423, 424, 425, 426, 428, 429, 431, 451].
              reject { |code| code == correct_code }.
              sample(random: random)
          end

        sample.annotation.add_antipattern('ignoring_status_code', breadcrumb + [raffled_code.to_s])
        raffled_code
      end

      def gen_path(sample, correct_path, method, prefix = '/')
        path = correct_path
        path = crudy_uri(path, method) if raffled_antipatterns.include?('crudy_uri')
        path = amorphous_uri(path) if raffled_antipatterns.include?('amorphous_uri')
        path = prefix + path

        sample.annotation.add_antipattern('crudy_uri', ['paths', path]) if raffled_antipatterns.include?('crudy_uri')
        sample.annotation.add_antipattern('amorphous_uri', ['paths', path]) if raffled_antipatterns.include?('amorphous_uri')

        path
      end

      def pregen_method(correct_method)
        return correct_method unless raffled_antipatterns.include?('inappropriate_http_method')

        HTTP_METHODS.filter { |m| m != correct_method }.sample(random: random)
      end

      def gen_method(sample, correct_method, pregenerated_method, breadcrumb)
        return correct_method unless raffled_antipatterns.include?('inappropriate_http_method')

        sample.annotation.add_antipattern('inappropriate_http_method', breadcrumb + [pregenerated_method])
        pregenerated_method
      end

      private

      def self.gen_crudy_uri_distortions
        distortions = {
          'post' => [],
          'get' => [],
          'head' => [],
          'put' => [],
          'patch' => [],
          'delete' => []
        }

        HTTP_METHOD_SYNONYMS.each do |method, synonyms|
          synonyms.each do |synonym|
            CRUDY_URI_SEPARATORS.each do |sep|
              distortions[method] << ->(path) { synonym + sep + path }
            end
          end
        end

        distortions.freeze
      end

      PUT_PATCH_SYNONYMS = ['update', 'put', 'patch', 'refresh', 'amend', 'renovate', 'revise', 'renew', 'restore'].freeze
      HTTP_METHOD_SYNONYMS = {
        'post' => [
          'create', 'post', 'build', 'construct', 'generate', 'make', 'produce', 'setup', 'spawn', 'start', 'author',
          'compose', 'fabricate', 'formulate', 'perform', 'new'
        ].freeze,
        'get' => [
          'read', 'get', 'fetch', 'retrieve', 'gather', 'scan', 'see', 'view'
        ].freeze,
        'head' => ['head'],
        'put' => PUT_PATCH_SYNONYMS,
        'patch' => PUT_PATCH_SYNONYMS,
        'delete' => [
          'delete', 'destroy', 'remove', 'eliminate', 'exclude', 'cancel', 'drop', 'obliterate', 'sanitize', 'squash',
          'trim', 'truncate'
        ]
      }.freeze
      CRUDY_URI_SEPARATORS = ['-', '_'].freeze
      CRUDY_URI_DISTORTIONS = gen_crudy_uri_distortions

      AMORPHOUS_URI_DISTORTIONS = [
        ->(path) { "#{path}.json" },
        ->(path) { "#{path}.xml" },
        ->(path) { "#{path}_.json" },
        ->(path) { "#{path}-.json" },
        ->(path) { "#{path}_.xml" },
        ->(path) { "#{path}-.xml" },
        ->(path) { "_#{path}" },
        ->(path) { "-#{path}" },
        ->(path) { path.upcase }
      ].freeze

      def crudy_uri(path, method)
        CRUDY_URI_DISTORTIONS[method].sample(random: random).call(path)
      end

      def amorphous_uri(path)
        AMORPHOUS_URI_DISTORTIONS.sample(random: random).call(path)
      end
    end
  end
end
