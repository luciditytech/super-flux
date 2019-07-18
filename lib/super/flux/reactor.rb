# frozen_string_literal: true

require_relative 'reactor/topic_name_factory'
require_relative 'reactor/execute_task'
require_relative 'reactor/retry_task'
require_relative 'reactor/governor'

module Super
  module Flux
    class Reactor
      include ConsumerResolver
      include LoggerResolver

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
        setup_topics
      end

      def start
        @state = :online
        @topics[0..-2].each { |topic| consumer.subscribe(topic) }
        # consumer.each_message(**CONSUMPTION_OPTIONS) { |message| process(message) }
        # consumer.each_batch(**CONSUMPTION_OPTIONS) { |batch| process(batch) }
        consumer.each_batch(automatically_mark_as_processed: false) { |batch| process(batch) }
      end

      def stop
        @state = :offline
        consumer.stop
      end

      private

      def setup_topics
        @topics = []

        0.upto(@task.settings.retries + 1) do |stage|
          @topics << TopicNameFactory.call(@task.settings, stage)
        end
      end

      def process(batch)
        batch.messages.each do |message|
          break if throttle(message)
          execute(message) || schedule_retry(message)
        end
      end

      # def process(message)
      #   return if throttle(message)
      #   return if execute(message)
      #
      #   schedule_retry(message)
      # end

      def throttle(message)
        Governor.call(message, stage_for(message.topic))
      end

      def execute(message)
        ExecuteTask.call(@task, message)
      end

      def schedule_retry(message)
        RetryTask.call(message, next_topic_for(message.topic))
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
