require 'json'
require 'digest'
require 'active_support/all'
require_relative 'sample'
require_relative 'create_operation'
require_relative 'annotation'

module OASDB
  module Generator
    class Engine
      attr_accessor :random, :oas_seed, :oas_seed_basename, :desired_num_samples, :antipatterns, :generated_samples, :raffled_antipatterns

      def initialize(random_generator_seed, oas_seed_path, desired_num_samples)
        @random = Random.new(random_generator_seed)
        @oas_seed = JSON.parse(File.read(oas_seed_path))
        @oas_seed_basename = File.basename(oas_seed_path, '.*')
        @desired_num_samples = desired_num_samples
        @antipatterns =
          JSON.
            parse(File.read('meta/antipatterns.json')).
            map { |antipattern| antipattern['name'] }

      end

      def run
        @generated_samples = []

        while generated_samples.length < desired_num_samples
          sample = generate_sample

          generated_samples << sample unless generated_samples.map(&:md5).include?(sample.md5)
        end

        @generated_samples.each do |s|
          sample_path = "samples/#{s.basename}"
          s.annotation.annotation_target = sample_path

          File.write(sample_path, s.raw)
          File.write("annotations/#{s.basename}", s.annotation.raw)
        end
      end

      def generate_sample
        antipatterns_num = random.rand(antipatterns.length) + 1 # +1 guarantees a range from 1 to length
        shuffled_antipatterns = antipatterns.shuffle(random: random)
        @raffled_antipatterns = ['amorphous_uri', 'ignoring_status_code'] # shuffled_antipatterns.take(antipatterns_num)

        sample = OASDB::Generator::Sample.new(oas_seed, oas_seed_basename, raffled_antipatterns)

        sample.contents['paths'].merge!(OASDB::Generator::CreateOperation.new.generate(self, sample))

        sample
      end

      def gen_response_code(correct_code)
        return correct_code.to_s unless raffled_antipatterns.include?('ignoring_status_code')

        if correct_code >= 200 && correct_code <= 299
          [200, 201, 202, 203, 204, 205, 206, 207, 208, 226].
            reject { |code| code == correct_code }.
            sample(random: random)
        end
      end

      def gen_path(sample, correct_path, prefix = '/')
        return prefix + correct_path unless raffled_antipatterns.include?('amorphous_uri')

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
        distorted_path = prefix + path_distortions.sample(random: random).call(correct_path)

        sample.annotation.add_antipattern('amorphous_uri', "paths.#{distorted_path}")
        distorted_path
      end
    end
  end
end

OASDB::Generator::Engine.new(121212, 'sample_seeds/incident_response.json', 1).run
