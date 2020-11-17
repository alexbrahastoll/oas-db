module OASDB
  module Generator
    class Annotation
      attr_accessor :contents

      def initialize
        @contents = {}
        contents['version'] = '0.1'
        contents['annotationTarget'] = '' # causes this key to come before 'antipatterns' when serializing
        contents['antipatterns'] = []
      end

      def annotation_target=(target)
        contents['annotationTarget'] = target
      end

      def add_antipattern(name, offender)
        antipattern = {
          name: name,
          offender: offender
        }

        contents['antipatterns'] << antipattern
      end

      def raw
        JSON.dump(contents)
      end
    end
  end
end
