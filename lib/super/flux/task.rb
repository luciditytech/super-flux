# frozen_string_literal: true

require_relative 'task/task_settings'
require_relative 'task/topic_name_factory'

module Super
  module Flux
    module Task
      DSL = %w[topic
               retries
               wait
               group_id
               start_from_beginning
               offset_commit_interval
               offset_commit_threshold].freeze

      def self.included(base)
        base.extend(ClassMethods)
        base.include(Super::Service)
      end

      module ClassMethods
        DSL.each do |method|
          define_method(method) do |value|
            settings.send("#{method}=", value)
          end
        end

        def topics
          @topics ||= (0..(settings.retries + 1)).map do |stage|
            TopicNameFactory.call(settings, stage)
          end
        end

        def settings
          @settings ||= TaskSettings.new
        end
      end
    end
  end
end
