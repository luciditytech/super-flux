# frozen_string_literal: true

require 'super'
require 'super/struct'
require 'json'
require 'securerandom'

require_relative '../lib/super/flux'

Super::Flux.configure do |config|
  config.kafka = {
    brokers: ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(','),
    client_id: 'flux'
  }

  config.producer_options = {
    max_buffer_size: 10_000,
    compression_codec: :lz4,
    required_acks: 1
  }
end

class Producer
  include Super::Flux::Producer

  topic 'tracks'
end

class Message
  include Super::Struct

  attribute :id
  attribute :payload
end

data = Array.new(100_000) do
  m = Message.new(id: SecureRandom.uuid, payload: SecureRandom.hex(256))
  JSON.dump(m.attributes)
end

logger = Logger.new(STDOUT)

start_time = Time.now

data.each_slice(16) do |slice|
  jobs = slice.map do |msg|
    Thread.new do
      Producer.produce(msg)
    end
  end

  jobs.map(&:join)
end

Producer.deliver
end_time = Time.now

logger.info("TPS: #{100_000.fdiv(end_time - start_time).round(1)}")
