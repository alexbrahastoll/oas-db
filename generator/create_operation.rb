module OASDB
  module Generator
    class CreateOperation
      def generate(engine, sample)
        correct_path_without_prefix = sample.base_resource_pretty_name.pluralize
        generated_path = engine.gen_path(sample, correct_path_without_prefix)

        {
          generated_path => {
            engine.gen_method(sample, 'post', ['paths', generated_path]) => {
              'summary' => "Creates a new #{sample.base_resource_pretty_name}",
              'operationId' => "create_#{sample.base_resource_pretty_name}",
              'tags' => [sample.base_resource_pretty_name],
              'requestBody' => {
                'description' => "The #{sample.base_resource_pretty_name} to be created.",
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
                engine.gen_response_code(sample, 201, ['paths', generated_path, 'post', 'responses']) => {
                  'description' => 'Created.',
                  'content' => {
                    'application/json' => {
                      'schema' => {
                        'description' => "The unique identifier of a #{sample.base_resource_pretty_name}.",
                        'type' => 'object',
                        'properties' => {
                          'id' => {
                            'description' => 'A generic integer ID.',
                            'type' => 'integer',
                            'format' => 'int64'
                          }
                        }
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
