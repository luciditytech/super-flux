# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Reactor::Processor do
  describe '#call' do
    subject { instance.call(message) }

    let(:instance) do
      described_class.new(
        task: task,
        logger: logger,
        consumer: consumer,
        adapter: adapter,
        topic_manager: topic_manager
      )
    end

    let(:message) { double(topic: 'TOPIC', value: 'VALUE') }
    let(:task) { double }
    let(:logger) { double }
    let(:consumer) { double }
    let(:adapter) { double }
    let(:topic_manager) { double }
    let(:stage) { 0 }
    let(:next_topic) { double }

    before do
      allow(topic_manager).to receive(:stage_for).with(message.topic).and_return(0)
      allow(topic_manager).to receive(:next_topic_for).with(message.topic).and_return(next_topic)
    end

    context 'when the message is throttled' do
      before do
        allow(Super::Flux::Reactor::Governor).to receive(:call)
          .with(message, stage)
          .and_return(true)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(StandardError)
      end
    end

    context 'and the message is not throttled' do
      before do
        allow(Super::Flux::Reactor::Governor).to receive(:call).and_return(false)
      end

      context 'and execution succeeds' do
        before do
          allow(task).to receive(:call).with(message.value).and_return(true)
          allow(consumer).to receive(:mark_message_as_processed).with(message)
        end

        it { is_expected.to eq(true) }
      end

      context 'and execution fails' do
        let(:error) { StandardError.new }

        before do
          allow(task).to receive(:call).with(message.value).and_raise(error)
          allow(logger).to receive(:error)
        end

        context 'and scheduling the retry succeeds' do
          before do
            allow(adapter).to receive(:deliver_message)
            allow(consumer).to receive(:mark_message_as_processed)
          end

          it { is_expected.to eq(true) }

          it 'schedules the retry' do
            expect(adapter).to receive(:deliver_message).with(message.value, topic: next_topic)
            subject
          end

          it 'marks the message as processed' do
            expect(consumer).to receive(:mark_message_as_processed).with(message)
            subject
          end

          it 'logs the error' do
            expect(logger).to receive(:error).with(error.message)
            subject
          end
        end

        context 'but scheduling the retry fails' do
          let(:error) { StandardError.new }

          before do
            allow(adapter).to receive(:deliver_message).and_raise(error)
          end

          it { is_expected.to eq(false) }

          it 'schedules the retry' do
            expect(adapter).to receive(:deliver_message).with(message.value, topic: next_topic)
            subject
          end

          it 'logs the error' do
            expect(logger).to receive(:error).with(error.message)
            subject
          end
        end
      end
    end
  end
end
