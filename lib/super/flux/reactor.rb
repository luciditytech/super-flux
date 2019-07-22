# frozen_string_literal: true

require_relative 'reactor/topic_name_factory'
require_relative 'reactor/governor'
require_relative 'reactor/topic_manager'
require_relative 'reactor/processor'

module Super
  module Flux
    class Reactor
      extend Forwardable

      CONSUMPTION_OPTIONS = {
        automatically_mark_as_processed: false
      }.freeze

      ThrottleError = Class.new(StandardError)

      def initialize(topic_manager:, consumer:, processor:, logger:)
        @topic_manager = topic_manager
        @consumer = consumer
        @logger = logger
        @processor = processor
        @state = :offline

        Signal.trap('INT') { stop }
      end

      def start
        @logger.info('Starting Reactor...')
        @state = :online
        topics[0..-2].each { |topic| @consumer.subscribe(topic) }
        run while @state == :online
      end

      def stop
        @state = :offline
        @consumer.stop
      end

      private

      def_delegators :@topic_manager, :topics
      def_delegator :@processor, :call, :process

      def run
        return if @state != :online

        @consumer.each_message(**CONSUMPTION_OPTIONS) { |message| process(message) }
      rescue Kafka::ProcessingError => e
        @logger.info("Throttled - #{e.topic} #{e.partition} #{e.offset}")
        reset_consumer(e)
        retry
      end

      def reset_consumer(error)
        @consumer.pause(error.topic, error.partition, timeout: 30)
        @consumer.seek(error.topic, error.partition, error.offset)
      end
    end
  end
end
