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

              def initialize
                @last_id = 0
                @ds = {}
              end

              def next_id
                @last_id += 1
              end

              def create_obj(payload)
                id = next_id
                obj = payload.merge({ 'id' => id })
                ds[id] = obj
                [true, obj]
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

        contents.concat <<~RUBY
          #{method} '#{path}' do
            request.body.rewind
            payload = JSON.parse(request.body.read)

            result, obj = api_helper.create_obj(payload)

            res_body = JSON.dump(obj.slice('id'))
            res_header = { 'Content-Type' => 'application/json' }

            [#{response_code.to_i}, res_header, res_body]
          end

        RUBY
      end

      def gen_code_read_operation(oas_seed, oas_operation)  
      end
    end
  end
end
