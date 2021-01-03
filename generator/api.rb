module OASDB
  module Generator
    class API
      attr_accessor :contents

      def gen_setup_code
        @contents = <<~RUBY
          require 'sinatra'
          require 'json'
          require 'yaml'

          module OASDB
            class GeneratedAPIHelper
              attr_reader :last_id, :ds

              OAS_RUBY_DATA_VALIDATION = {
                'string' => ->(data) { raise ArgumentError if String(data).length == 0 },
                'integer' => ->(data) { Integer(data) }
              }.freeze

              def initialize
                @last_id = 0
                @ds = {}
              end

              def next_id
                @last_id += 1
              end

              def validate_field(name, value, schema)
                OAS_RUBY_DATA_VALIDATION[schema.dig(name, 'type')].call(value)
                true
              rescue ArgumentError
                false
              end

              def valid_obj?(payload, schema)
                validation_results = {}

                payload.each do |name, value|
                  validation_results[name] = validate_field(name, value, schema)
                end

                validation_results.values.all?
              end

              def create_obj(payload)
                id = next_id
                obj = payload.merge({ 'id' => id })
                ds[id] = obj
                [true, obj]
              end

              def read_obj(key)
                obj = ds[key]
                [!obj.nil?, obj]
              end
            end
          end

          api_helper = OASDB::GeneratedAPIHelper.new

        RUBY
      end

      def gen_code_create_operation(oas_seed, oas_operation)
        path = oas_operation.keys.first
        method = oas_operation[path].keys.first
        response_code = oas_operation[path][method]['responses'].keys.first
        schema_location = oas_operation[path][method]['requestBody']['content']['application/json']['schema']['$ref'].split('/')[1..-1].concat(['properties'])
        schema = oas_seed.dig(*schema_location)

        contents.concat <<~RUBY
          #{method} '#{path}' do
            request.body.rewind
            payload = JSON.parse(request.body.read)
            halt 422 unless api_helper.valid_obj?(payload, #{schema})

            result, obj = api_helper.create_obj(payload)

            res_body = JSON.dump(obj.slice('id'))
            res_header = { 'Content-Type' => 'application/json' }

            [#{response_code.to_i}, res_header, res_body]
          end

        RUBY
      end

      def gen_code_read_operation(oas_seed, oas_operation)
        path = oas_operation.keys.first
        method = oas_operation[path].keys.first
        response_code = oas_operation[path][method]['responses'].keys.first

        param = path.match(/\{(.+)\}/).captures.first
        sinatra_path = path.gsub(/\{.+\}/, ":#{param}")

        contents.concat <<~RUBY
          #{method} '#{sinatra_path}' do
            request.body.rewind

            obj_id = Integer(params['#{param}'])
            found, obj = api_helper.read_obj(obj_id)

            halt 404 unless found

            res_body = JSON.dump(obj)
            res_header = { 'Content-Type' => 'application/json' }

            [#{response_code.to_i}, res_header, res_body]

          rescue ArgumentError
            halt 404
          end

        RUBY
      end
    end
  end
end
