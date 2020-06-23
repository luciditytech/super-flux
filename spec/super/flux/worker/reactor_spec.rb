# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Worker::Reactor do
  let(:instance) do
    described_class.new(
      logger: logger,
      topic: topic,
      task: task,
      consumer: consumer,
      options: { run_once: true }
    )
  end

  let(:logger) { double }
  let(:topic) { 'TOPIC' }
  let(:consumer) { double }
  let(:start_from_beginning) { true }
  let(:settings) { double(start_from_beginning: start_from_beginning) }
  let(:task) { double(settings: settings) }
  let(:max_bytes_per_partition) { 128 * 1_024 }

  describe '#start' do
    subject { instance.start }
    let(:message) { double }
    let(:batch) { double(messages: [message]) }

    shared_examples_for 'a subscriber' do
      it 'subscribes to topic' do
        subject
      rescue StandardError
        expect(consumer).to have_received(:subscribe).with(
          topic,
          start_from_beginning: start_from_beginning,
          max_bytes_per_partition: max_bytes_per_partition
        )
      end
    end

    before do
      allow(logger).to receive(:info)
      allow(consumer).to receive(:subscribe).with(
        topic,
        start_from_beginning: start_from_beginning,
        max_bytes_per_partition: max_bytes_per_partition
      )
      allow(consumer).to receive(:each_batch).and_yield(batch)
      allow(consumer).to receive(:stop)
    end

    context 'when the message executes correctly' do
      before do
        allow(Super::Flux::Worker::Processor).to receive(:call).with(task, message).and_return(true)
      end

      it_behaves_like 'a subscriber'

      it 'executes the message' do
        expect(Super::Flux::Worker::Processor).to receive(:call).with(task, message)
        subject
      end
    end
  end
end
