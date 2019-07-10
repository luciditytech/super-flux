# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class TopicFactory
        include Super::Service

        def call(settings, stage)
          base_name = settings.topic
          max_try = settings.retries
          return base_name if stage.zero?
          return base_name + "-try-#{stage}" if stage <= max_try

          base_name + '-dlq'
        end
      end
    end
  end
end
