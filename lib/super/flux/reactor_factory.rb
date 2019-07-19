module Super
  module Flux
    class ReactorFactory
      include Super::Service

      def call(params = {})
        @params = params
        setup_topic_manager
        setup_consumer
        setup_batch_manager

        Reactor.new(**reactor_params)
      end

      private

      def task
        @params[:task]
      end

      def setup_topic_manager
        @topic_manager = Reactor::TopicManager.new(task.settings, stages: @params[:stages])
      end

      def setup_consumer
        @consumer = ConsumerFactory.call(task.settings, adapter: @params[:adapter])
      end

      def setup_batch_manager
        @batch_manager =  Reactor::BatchManager.new(
          task: task,
          topic_manager: @topic_manager,
          adapter: @params[:adapter],
          consumer: @consumer,
          logger: @params[:logger],
        )
      end

      def reactor_params
        {
          topic_manager: @topic_manager,
          consumer: @consumer,
          batch_manager: @batch_manager,
          logger: @params[:logger]
        }.compact
      end
    end
  end
end
