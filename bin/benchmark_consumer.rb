# frozen_string_literal: true

require_relative '../lib/super/flux'

Super::Flux.configure do |config|
  config.kafka = {
    seed_brokers: ENV.fetch('KAFKA_BROKERS', 'localhost:9092').split(','),
    client_id: 'flux'
  }

  config.producer_options = {
    max_buffer_size: 10_000,
    required_acks: 1
  }
end

class TestTask
  include Super::Flux::Task

  topic 'tracks'
  group_id 'test'
  retries 2

  def call(_data)
    raise
  end
end

Super::Flux.run(TestTask)
