# frozen_string_literal: true

module Super
  module Flux
    class Worker
      class Processor
        include Super::Service

        def call(task, message)
          @task = task
          execute(message) || prepare_retry(message)
        end

        private

        def execute(message)
          @task.call(message.value)
          true
        rescue StandardError => e
          puts e.full_message
          false
        end

        def prepare_retry(message)
          Super::Flux.pool.with do |adapter|
            puts next_topic_for(message.topic)
            adapter.deliver_message(message.value, topic: next_topic_for(message.topic))
          end

          true
        rescue StandardError => e
          puts e.full_message
          false
        end

        def next_topic_for(topic)
          @task.topics[stage_for(topic) + 1]
        end

        def stage_for(topic)
          @task.topics.index(topic)
        end
      end
    end
  end
end
