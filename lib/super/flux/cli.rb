# frozen_string_literal: true

module Super
  module Flux
    class CLI < Thor
      desc 'process TASK_CLASS', 'Task Class to process'
      option :load
      option :stages
      def process(name)
        load File.expand_path(options[:load], Dir.pwd)
        klass = Kernel.const_get(name)
        Super::Flux.run(klass, stages: stages_for(options[:stages]))
      end

      private

      def stages_for(string)
        return unless string
        return Range.new(*([string.to_i] * 2)) unless string =~ /-/

        Range.new(*string.split('-').map(&:to_i))
      end
    end
  end
end
