# frozen_string_literal: true

require_relative 'task/task_settings'

module Super
  module Flux
    module Task
      DSL = %w[topic
               group_id
               retries
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

        def settings
          @settings ||= TaskSettings.new
        end
      end
    end
  end
end
