# frozen_string_literal: true

module Super
  module Flux
    class Configuration < OpenStruct
      def logger
        self[:logger] || self.logger = Logger.new(STDOUT)
      end
    end
  end
end
