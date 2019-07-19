# frozen_string_literal: true

module Super
  module Flux
    class ConsumerFactory
      include Super::Service

      def call(settings, adapter: Super::Flux.adapter)
        @settings = settings
        adapter.consumer(consumer_options)
      end

      private

      def consumer_options
        {
          group_id: @settings.group_id,
          offset_commit_interval: @settings.offset_commit_interval || 5,
          offset_commit_threshold: @settings.offset_commit_threshold || 10_000
        }.compact
      end
    end
  end
end
