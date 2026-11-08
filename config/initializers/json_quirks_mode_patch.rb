module ActiveSupport
  module JSON
    module Encoding
      class JSONGemEncoder
        private
        def stringify(jsonified)
          ::JSON.generate(jsonified)
        end
      end
    end
  end
end
