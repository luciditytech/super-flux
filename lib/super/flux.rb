# frozen_string_literal: true

require 'ostruct'
require 'forwardable'
require 'super'

require_relative 'flux/version'
require_relative 'flux/errors'
require_relative 'flux/processor'
require_relative 'flux/logger_resolver'
require_relative 'flux/adapter_resolver'
require_relative 'flux/configuration'
require_relative 'flux/task'
require_relative 'flux/reactor_pool'
require_relative 'flux/reactor_pool_factory'
require_relative 'flux/reactor'
require_relative 'flux/governor'
require_relative 'flux/execute_task'
require_relative 'flux/retry_task'

module Super
  module Flux
    def self.configure(&block)
      block.call(configuration)
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.logger
      configuration.logger
    end

    def self.adapter
      configuration.adapter
    end

    def self.run(task)
      @reactor = Reactor.new(task)
      @reactor.start
    end
  end
end
