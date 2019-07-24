# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Reactor do
  TOPICS = %w[TOPIC TOPIC-try-1 TOPIC-dlq].freeze

  let(:instance) do
    described_class.new(
      topic_manager: topic_manager,
      consumer: consumer,
      processor: processor,
      logger: logger,
      options: {
        run_once: true
      }
    )
  end

  let(:task) { double }
  let(:logger) { double }
  let(:consumer) { double }
  let(:topic_manager) { double }
  let(:processor) { double }
  let(:topics) { TOPICS }

  describe '#start' do
    subject { instance.start }

    let(:message) { double }

    before do
      allow(logger).to receive(:info)
      allow(topic_manager).to receive(:active_topics).and_return(topics)

      TOPICS.each do |topic|
        allow(consumer).to receive(:subscribe).with(topic)
      end

      allow(consumer).to receive(:each_message).and_yield(message)
      allow(consumer).to receive(:stop)
    end

    shared_examples_for 'a topic subscriber' do
      it 'subscribes to the main topic' do
        subject
      rescue StandardError
        expect(consumer).to have_received(:subscribe).with('TOPIC')
      end

      it 'subscribes to the retry topic' do
        subject
      rescue StandardError
        expect(consumer).to have_received(:subscribe).with('TOPIC-try-1')
      end

      it 'does not subscribe to the DLQ topic' do
        subject
      rescue StandardError
        expect(consumer).to_not have_received(:subscribe).with('TOPIC-dlq')
      end
    end

    context 'when the message executes correctly' do
      before do
        allow(processor).to receive(:call).with(message).and_return(true)
      end

      it_behaves_like 'a topic subscriber'

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

      it_behaves_like 'a topic subscriber'

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
