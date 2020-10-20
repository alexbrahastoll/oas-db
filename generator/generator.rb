# TODO
# Gerar arquivo de anotação

require 'json'
require 'active_support/all'

module OASDB
  class Generator
    attr_reader :setup_done, :random, :antipatterns, :raffled_antipatterns, :oas_seed, :base_resource, :oas

    def initialize(random_generator_seed = 121237)
      @setup_done = false
      @random = Random.new(random_generator_seed)
    end

    def setup
      return true if setup_done

      @antipatterns =
        JSON.
          parse(File.read('meta/antipatterns.json')).
          map { |antipattern| antipattern['name'] }.
          shuffle(random: random)
      @oas_seed = JSON.parse(File.read('sample_seeds/incident_response.json'))
      @base_resource = oas_seed['components']['schemas'].slice(oas_seed['components']['schemas'].keys.first)
    end

    def generate
      setup

      antipatterns_num = random.rand(antipatterns.length) + 1 # +1 guarantees a range from 1 to length
      @raffled_antipatterns = ['amorphous_uri', 'inappropriate_http_method'] # antipatterns.take(antipatterns_num)

      @oas = {}
      oas['info'] = oas_seed['info']
      oas['components'] = oas_seed['components']

      oas['paths'] = {}
      oas['paths'].merge!(gen_post)

      # raffled_antipatterns.each { |antipattern| send(antipattern) }
      amorphous_uri

      File.write("samples/g_incident_response_#{random.seed}.json", JSON.dump(oas))
    end

    private

    def base_resource_name
      base_resource.keys.first
    end

    def base_resource_pretty_name
      base_resource_name.downcase
    end

    def gen_post
      path = "/#{base_resource_pretty_name.pluralize}"
      {
        path => {
          'post' => {
            'summary' => "Creates a new #{base_resource_pretty_name}",
            'operationId' => "create_#{base_resource_pretty_name}",
            'tags' => [base_resource_pretty_name],
            'requestBody' => {
              'description' => "The #{base_resource_pretty_name} to be created.",
              'required' => true,
              'content' => {
                'application/json' => {
                  'schema' => {
                    '$ref' => "#/components/schemas/#{base_resource_name}"
                  }
                }
              }
            },
            'responses' => {
              gen_response_code(201) => {
                'description' => 'Created.',
                'content' => {
                  'application/json' => {
                    'schema' => {
                      'description' => "The unique identifier of a #{base_resource_pretty_name}.",
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

    def gen_response_code(correct_code)
      return correct_code.to_s unless raffled_antipatterns.include?('inappropriate_http_method')

      if correct_code >= 200 && correct_code <= 299
        [200, 201, 202, 203, 204, 205, 206, 207, 208, 226].
          reject { |code| code == correct_code }.
          sample(random: random)
      end
    end

    def amorphous_uri
      path_distortions = [
        ->(path) { "#{path}.json" },
        ->(path) { "#{path}.xml" },
        ->(path) { "#{path}_.json" },
        ->(path) { "#{path}-.json" },
        ->(path) { "#{path}_.xml" },
        ->(path) { "#{path}-.xml" },
        ->(path) { "_#{path}" },
        ->(path) { "-#{path}" },
        ->(path) { path.upcase }
      ]

      oas['paths'].transform_keys! { |path| path_distortions.sample(random: random).call(path) }
    end
  end
end

OASDB::Generator.new.generate
