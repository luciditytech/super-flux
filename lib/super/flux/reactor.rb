# frozen_string_literal: true

require_relative 'reactor/consumer_factory'
require_relative 'reactor/topic_factory'

module Super
  module Flux
    class Reactor
      include AdapterResolver

      CONSUMPTION_OPTIONS = {
        automatically_mark_as_processed: false
      }.freeze

      def self.run(*args)
        new(*args).start
      end

      def initialize(task)
        @task = task
        @state = :offline
        Signal.trap('INT') { stop }
        setup_consumer
        setup_topics
      end

      def start
        @state = :online
        @topics[0..-2].each { |topic| @consumer.subscribe(topic) }
        @consumer.each_message(CONSUMPTION_OPTIONS) { |message| process(message) }
      end

      def stop
        @consumer.stop
        @state = :offline
      end

      private

      def setup_consumer
        @consumer = ConsumerFactory.call(@task.settings)
      end

      def setup_topics
        @topics = []

        0.upto(@task.settings.retries + 1) do |stage|
          @topics << TopicFactory.call(@task.settings, stage)
        end
      end

      def process(message)
        throttle(message)
        execute(message) || schedule_retry(message)
      end

      def throttle(message)
        Governor.call(message, @consumer, stage_for(message.topic))
      end

      def execute(message)
        ExecuteTask.call(@task, message, @consumer)
      end

      def schedule_retry(message)
        RetryTask.call(message, @consumer, next_topic_for(message.topic))
      end

      def stage_for(topic)
        @topics.index(topic)
      end

      def next_topic_for(topic)
        @topics[@topics.index(topic) + 1]
      end
    end
  end
end
