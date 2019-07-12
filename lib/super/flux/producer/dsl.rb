# frozen_string_literal: true

module Super
  module Flux
    module Producer
      module DSL
        def self.included(base)
          base.class_eval do
            %i[max_buffer_size topic].each do |method|
              define_singleton_method(method) do |value|
                configuration.send("#{method}=", value)
              end
            end
          end
        end
      end
    end
  end
end
