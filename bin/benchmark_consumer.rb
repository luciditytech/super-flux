# frozen_string_literal: true
require_relative '../lib/super/flux'

Super::Flux.configure do |config|
  config.kafka = {
    # logger: Logger.new(STDOUT),
    brokers: ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(','),
    client_id: 'flux'
  }

  config.producer_options = {
    max_buffer_size: 10_000,
    compression_codec: :lz4,
    required_acks: 1
  }
end

class TestTask
  include Super::Flux::Task

  topic 'tracks'
  group_id 'test'
  retries 2

  def call(data)
    raise
  end
end

Super::Flux.run(TestTask)
