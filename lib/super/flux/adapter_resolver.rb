# frozen_string_literal: true

module Super
  module Flux
    module AdapterResolver
      def self.included(base)
        base.class_eval do
          private

          def adapter
            Super::Flux.adapter
          end
        end
      end
    end
  end
end
