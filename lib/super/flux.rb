# frozen_string_literal: true

require 'ostruct'
require 'forwardable'
require 'kafka'
require 'weakref'
require 'super'
require 'super/resource_pool'

require_relative 'flux/version'
require_relative 'flux/errors'
require_relative 'flux/logger_resolver'
require_relative 'flux/adapter_resolver'
require_relative 'flux/consumer_resolver'
require_relative 'flux/consumer_factory'
require_relative 'flux/configuration'
require_relative 'flux/task'
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

    def self.run(task)
      @consumer = ConsumerFactory.call(task.settings)
      @reactor = Reactor.new(task)
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
