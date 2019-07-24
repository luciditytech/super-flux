# frozen_string_literal: true

module Super
  module Flux
    module Errors
      TaskNotDefined = Class.new(StandardError)
      StageRangeInvalid = Class.new(StandardError)
    end
  end
end
