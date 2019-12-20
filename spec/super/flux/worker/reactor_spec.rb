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
  let(:task) { double }

  describe '#start' do
    subject { instance.start }
    let(:message) { double }
    let(:batch) { double(messages: [message]) }

    shared_examples_for 'a subscriber' do
      it 'subscribes to topic' do
        subject
      rescue StandardError
        expect(consumer).to have_received(:subscribe).with(topic)
      end
    end

    before do
      allow(logger).to receive(:info)
      allow(consumer).to receive(:subscribe).with(topic)
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
