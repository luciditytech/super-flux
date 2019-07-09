# frozen_string_literal: true

module Super
  module Flux
    module LoggerResolver
      def self.included(base)
        base.class_eval do
          private

          def logger
            Super::Flux.logger
          end
        end
      end
    end
  end
end
