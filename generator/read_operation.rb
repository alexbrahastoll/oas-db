module OASDB
  module Generator
    class ReadOperation
      def generate(engine, sample)
        correct_path_without_prefix =
          "#{sample.base_resource_pretty_name.pluralize}/{#{sample.resource_id_name(sample.base_resource_name, :underscore)}}"
        pregenerated_method = engine.pregen_method('get')
        generated_path = engine.gen_path(sample, correct_path_without_prefix, pregenerated_method)

        {
          generated_path => {
            engine.gen_method(sample, 'get', pregenerated_method, ['paths', generated_path]) => {
              'summary' => "Retrieves a #{sample.base_resource_pretty_name}",
              'operationId' => "read_#{sample.base_resource_pretty_name}",
              'tags' => [sample.base_resource_pretty_name],
              'parameters' => [
                { '$ref' => "#/components/parameters/#{sample.resource_id_name(sample.base_resource_name, :camelcase)}" }
              ],
              'responses' => {
                engine.gen_response_code(sample, 200, ['paths', generated_path, pregenerated_method, 'responses']) => {
                  'description' => 'OK.',
                  'content' => {
                    'application/json' => {
                      'schema' => {
                        'allOf' => [
                          { '$ref' => '#/components/schemas/Id' },
                          { '$ref' => "#/components/schemas/#{sample.base_resource_name}" }
                        ]
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end
    end
  end
end
