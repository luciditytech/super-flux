# frozen_string_literal: true

module Super
  module Flux
    class CLI < Thor
      desc 'process TASK_CLASS', 'Task Class to process'
      option :load
      def process(name)
        load File.expand_path(options[:load], Dir.pwd)
        klass = Kernel.const_get(name)
        Super::Flux.run(klass)
      end
    end
  end
end
