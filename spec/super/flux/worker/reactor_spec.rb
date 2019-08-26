# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Worker::Reactor do
  let(:instance) do
    described_class.new(
      logger: logger,
      topic: topic,
      consumer: consumer,
      processor: processor,
      options: { run_once: true }
    )
  end

  let(:logger) { double }
  let(:topic) { 'TOPIC' }
  let(:consumer) { double }
  let(:processor) { double }

  describe '#start' do
    subject { instance.start }
    let(:message) { double }

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
      allow(consumer).to receive(:each_message).and_yield(message)
      allow(consumer).to receive(:stop)
    end

    context 'when the message executes correctly' do
      before do
        allow(processor).to receive(:call).with(message).and_return(true)
      end

      it_behaves_like 'a subscriber'

      it 'executes the message' do
        expect(processor).to receive(:call).with(message)
        subject
      end
    end

    context 'when the message execution fails' do
      let(:error) do
        Kafka::ProcessingError.new('TOPIC', 'PARTITION', 100)
      end

      before do
        allow(processor).to receive(:call).with(message).and_raise(error)
        allow(logger).to receive(:info)
        allow(consumer).to receive(:pause)
        allow(consumer).to receive(:seek)
      end

      it_behaves_like 'a subscriber'

      it 'executes the message' do
        subject
      rescue StandardError
        expect(processor).to have_received(:call).with(message)
      end

      it 'logs the error' do
        subject
      rescue StandardError
        expect(logger).to have_received(:info).with(an_instance_of(String))
      end

      it 'pauses the topic and partition' do
        subject
      rescue StandardError
        expect(consumer).to have_received(:pause)
          .with(error.topic, error.partition, timeout: 30)
      end

      it 'syncs the paused topic and partition to the right offset' do
        subject
      rescue StandardError
        expect(consumer).to have_received(:seek)
          .with(error.topic, error.partition, error.offset)
      end
    end
  end
end
