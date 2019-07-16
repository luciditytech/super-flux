# frozen_string_literal: true

module Super
  module Flux
    module Task
      class TaskSettings < OpenStruct
        def retries
          self[:retries] || self.retries = 5
        end
      end
    end
  end
end
