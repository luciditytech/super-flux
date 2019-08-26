# frozen_string_literal: true

module Super
  module Flux
    module Task
      class TopicNameFactory
        include Super::Service
        extend Forwardable

        def call(settings, stage)
          @settings = settings
          @stage = stage
          return topic if @stage.zero?
          return stage_topic if @stage <= retries

          dead_letter_topic
        end

        private

        def_delegators :@settings, :topic, :retries, :group_id

        def stage_topic
          [topic, group_id, 'try', @stage].compact.join('-')
        end

        def dead_letter_topic
          [topic, group_id, 'dlq'].compact.join('-')
        end
      end
    end
  end
end
