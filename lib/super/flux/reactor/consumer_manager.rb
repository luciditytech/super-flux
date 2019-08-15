# frozen_string_literal: true

module Super
  module Flux
    class Reactor
      class ConsumerManager
        def initialize(topics:, settings:, adapter: Super::Flux.adapter)
          @adapter = adapter
          @consumers = {}

          topics.each do |topic|
            @consumers[topic] =
          end
        end

        def find(topic)
          @consumers[topic]
        end

        private

        def consumer_for(topic)
          {
            group_id: @settings.group_id,
            offset_commit_interval: @settings.offset_commit_interval || 5,
            offset_commit_threshold: @settings.offset_commit_threshold || 10_000
          }.compact
        end
      end
    end
  end
end
