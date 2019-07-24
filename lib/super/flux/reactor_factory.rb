# frozen_string_literal: true

module Super
  module Flux
    class ReactorFactory
      extend Forwardable
      include Super::Service

      def call(params = {})
        @params = params
        setup_topic_manager
        setup_consumer
        setup_processor

        Reactor.new(**reactor_params)
      end

      private

      def_delegators :task, :settings

      def task
        @params[:task]
      end

      def setup_topic_manager
        @topic_manager = Reactor::TopicManager.new(settings, stages: @params[:stages])
      end

      def setup_consumer
        @consumer = ConsumerFactory.call(settings, adapter: @params[:adapter])
      end

      def setup_processor
        @processor = Reactor::Processor.new(
          task: task,
          topic_manager: @topic_manager,
          adapter: @params[:adapter],
          consumer: @consumer,
          logger: @params[:logger]
        )
      end

      def reactor_params
        {
          topic_manager: @topic_manager,
          consumer: @consumer,
          processor: @processor,
          logger: @params[:logger]
        }.compact
      end
    end
  end
end
