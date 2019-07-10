# frozen_string_literal: true

module Super
  module Flux
    module ConsumerResolver
      def self.included(base)
        base.class_eval do
          private

          def consumer
            Super::Flux.consumer
          end
        end
      end
    end
  end
end
