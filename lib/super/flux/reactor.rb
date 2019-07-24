# frozen_string_literal: true

require_relative 'reactor/topic_name_factory'
require_relative 'reactor/governor'
require_relative 'reactor/topic_manager'
require_relative 'reactor/processor'

module Super
  module Flux
    class Reactor
      extend Forwardable
      include Super::Struct

      attribute :topic_manager
      attribute :consumer
      attribute :processor
      attribute :logger
      attribute :options
      attribute :state

      CONSUMPTION_OPTIONS = {
        automatically_mark_as_processed: false
      }.freeze

      ThrottleError = Class.new(StandardError)

      def initialize(**args)
        super(args)
        self.state ||= :offline
        self.options ||= {}
        @loops = 0

        Signal.trap('INT') { stop }
        Signal.trap('TERM') { stop }
      end

      def start
        logger.info('Starting Reactor...')
        self.state = :online
        active_topics.each { |topic| subscribe(topic) }
        run while alive?
      end

      def stop
        self.state = :offline
        consumer.stop
      end

      private

      def_delegators :topic_manager, :active_topics
      def_delegator :processor, :call, :process
      def_delegators :consumer, :subscribe, :each_message, :pause, :seek

      def alive?
        return false if options[:run_once] && @loops.positive?

        state == :online
      end

      def run
        return unless alive?

        @loops += 1
        each_message(**CONSUMPTION_OPTIONS) { |message| raise unless process(message) }
      rescue Kafka::ProcessingError => e
        reset_consumer(e.topic, e.partition, e.offset)
        return stop unless alive?

        retry
      end

      def reset_consumer(topic, partition, offset)
        logger.info("Throttled - #{topic} #{partition} #{offset}")
        pause(topic, partition, timeout: 30)
        seek(topic, partition, offset)
      end
    end
  end
end
