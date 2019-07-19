module Super
  module Flux
    class Reactor
      class TopicManager
        attr_reader :topics

        def initialize(settings, stages: nil)
          @topics = []

          (stages || (0..(settings.retries + 1)).to_a).each do |stage|
            @topics << TopicNameFactory.call(settings, stage)
          end
        end

        def stage_for(topic)
          @topics.index(topic)
        end

        def next_topic_for(topic)
          @topics[stage_for(topic) + 1]
        end
      end
    end
  end
end
