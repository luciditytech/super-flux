# frozen_string_literal: true

require 'ostruct'
require 'forwardable'
require 'kafka'
require 'super'
require 'super/struct'

require_relative 'flux/version'
require_relative 'flux/errors'
require_relative 'flux/logger_resolver'
require_relative 'flux/adapter_resolver'
require_relative 'flux/consumer_factory'
require_relative 'flux/configuration'
require_relative 'flux/task'
require_relative 'flux/reactor_factory'
require_relative 'flux/reactor'
require_relative 'flux/producer'

module Super
  module Flux
    extend SingleForwardable

    def_delegators :configuration,
                   :logger,
                   :concurrency,
                   :concurrency=,
                   :adapter,
                   :adapter=,
                   :producer,
                   :producer=,
                   :environment

    def self.configure(&block)
      block.call(configuration)
    end

    def self.run(task, stages: nil)
      @reactor = ReactorFactory.call(
        task: task,
        adapter: adapter,
        stages: stages,
        logger: logger
      )

      @reactor.start
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.consumer
      @consumer
    end
  end
end
