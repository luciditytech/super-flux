# frozen_string_literal: true

require_relative 'reactor/topic_name_factory'
require_relative 'reactor/governor'
require_relative 'reactor/topic_manager'
require_relative 'reactor/batch_manager'

module Super
  module Flux
    class Reactor
      extend Forwardable

      CONSUMPTION_OPTIONS = {
        automatically_mark_as_processed: false
      }.freeze

      ThrottleError = Class.new(StandardError)

      def initialize(topic_manager:, consumer:, batch_manager:, logger:)
        @topic_manager = topic_manager
        @consumer = consumer
        @logger = logger
        @batch_manager = batch_manager
        @state = :offline

        Signal.trap('INT') { stop }
      end

      def start
        @logger.info('Starting Reactor...')
        @state = :online
        topics[0..-2].each { |topic| @consumer.subscribe(topic) }

        loop do
          begin
            @consumer.each_message(**CONSUMPTION_OPTIONS) { |message| process(message) }
            break if @state != :online
          rescue Kafka::ProcessingError => e
            @logger.info("Throttled, waiting #{e.topic} #{e.partition} #{e.offset}")
            @consumer.pause(e.topic, e.partition, timeout: 30)
            @consumer.seek(e.topic, e.partition, e.offset)
            retry
          end
        end
      end

      def stop
        @state = :offline
        @consumer.stop
      end

      private

      def_delegators :@topic_manager, :topics
      def_delegator :@batch_manager, :call, :process
    end
  end
end
