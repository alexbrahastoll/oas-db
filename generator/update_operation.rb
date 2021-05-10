module OASDB
  module Generator
    class UpdateOperation
      def generate(engine, sample)
        correct_path_without_prefix =
          "#{sample.base_resource_pretty_name.pluralize}/{#{sample.resource_id_name(sample.base_resource_name, :underscore)}}"
        pregenerated_method = engine.pregen_method('put')
        generated_path = engine.gen_path(sample, correct_path_without_prefix, pregenerated_method)

        {
          generated_path => {
            engine.gen_method(sample, 'put', pregenerated_method, ['paths', generated_path]) => {
              'summary' => "Updates a #{sample.base_resource_pretty_name}",
              'operationId' => "update_#{sample.base_resource_pretty_name}",
              'tags' => [sample.base_resource_pretty_name],
              'parameters' => [
                { '$ref' => "#/components/parameters/#{sample.resource_id_name(sample.base_resource_name, :camelcase)}" }
              ],
              'requestBody' => {
                'description' => "The #{sample.base_resource_pretty_name} to be updated.",
                'required' => true,
                'content' => {
                  'application/json' => {
                    'schema' => {
                      '$ref' => "#/components/schemas/#{sample.base_resource_name}"
                    }
                  }
                }
              },
              'responses' => {
                engine.gen_response_code(sample, 200, ['paths', generated_path, pregenerated_method, 'responses']) => {
                  'description' => 'OK.',
                },
                engine.gen_response_code(sample, 404, ['paths', generated_path, pregenerated_method, 'responses']) => {
                  'description' => 'Not found.'
                }
              }
            }
          }
        }
      end
    end
  end
end
