module OASDB
  module Generator
    class Annotation
      attr_accessor :contents

      def initialize
        @contents = {}
        contents['version'] = '0.2'
        contents['annotationTarget'] = '' # causes this key to come before 'antipatterns' when serializing
        contents['spec_issues'] = []
        contents['api_issues'] = []
      end

      def annotation_target=(target)
        contents['annotationTarget'] = target
      end

      def add_antipattern(name, offender)
        antipattern = {
          name: name,
          offender: offender
        }

        contents['spec_issues'] << antipattern
      end

      def add_api_issue(name, offender = nil)
        api_issue = {
          name: name,
          offender: offender
        }

        contents['api_issues'] << api_issue
      end

      def raw
        JSON.dump(contents)
      end
    end
  end
end
