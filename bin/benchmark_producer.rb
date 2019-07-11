require 'super'
require 'super/struct'
require 'json'
require 'securerandom'

require_relative '../lib/super/flux'

Super::Flux.configure do |config|
  config.kafka = {
    brokers: %w(localhost:9092),
    client_id: 'flux'
  }

  config.concurrency = 8
end

class Producer < Super::Flux::Producer
end


Producer.configure do |config|
  config.producer = Super::Flux.adapter.producer(
    max_buffer_size: 10000,
    compression_codec: :lz4,
    compression_threshold: 10,
    required_acks: 1
  )
end

class Message
  include Super::Struct

  attribute :id
  attribute :payload
end

data = Array.new(100000) do
  m = Message.new(id: SecureRandom.uuid, payload: SecureRandom.hex(256))
  JSON.dump(m.attributes)
end

logger = Logger.new(STDOUT)

i = 0
start_time = Time.now

data.each_slice(16) do |slice|
  jobs = slice.map do |msg|
    Thread.new do
      Producer.produce(msg, topic: 'tracks')
    end
  end

  jobs.map(&:join)
end

Producer.deliver
end_time = Time.now

logger.info("TPS: #{100_000.fdiv(end_time - start_time).round(1)}")
