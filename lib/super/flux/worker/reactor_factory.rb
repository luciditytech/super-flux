# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class ReactorFactory
        include Super::Service

        def call(params = {})
          @params = params
          setup_reactor
          add_processor
          result
        end

        private

        def result
          @reactor
        end

        def setup_reactor
          @reactor = Reactor.new(
            logger: @params[:logger],
            topic: @params[:topic],
            consumer: @params[:consumer],
            options: @params[:options]
          )
        end

        def add_processor
          @reactor.processor = Processor.new(
            task: @params[:task],
            adapter: @params[:adapter],
            consumer: @params[:consumer],
            logger: @params[:logger]
          )
        end
      end
    end
  end
end
