# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Worker::Processor do
  describe '.call' do
    subject { described_class.call(task, message) }

    let(:message) { double(topic: 'TOPIC', value: 'VALUE') }
    let(:topics) { %w[TOPIC TOPIC-try-1] }
    let(:task) { double }
    let(:task_settings) { double(wait: 10) }
    let(:logger) { double }
    let(:consumer) { double }
    let(:adapter) { double }
    let(:stage) { 0 }
    let(:pool) { double }

    before do
      allow(task).to receive(:topics).and_return(topics)
      allow(task).to receive(:settings).and_return(task_settings)
      allow(Super::Flux).to receive(:pool).and_return(pool)
      allow(pool).to receive(:with).and_yield(adapter)
    end

    # context 'when the message is throttled' do
    #   before do
    #     allow(Super::Flux::Worker::Governor).to receive(:call)
    #       .with(message, stage, wait: task_settings.wait)
    #       .and_return(true)
    #   end
    #
    #   it 'raises an error' do
    #     expect { subject }.to raise_error(StandardError)
    #   end
    # end

    context 'when the message is not throttled' do
      # before do
      #   allow(Super::Flux::Worker::Governor).to receive(:call).and_return(false)
      #   allow(logger).to receive(:debug)
      # end

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
          allow(error).to receive(:full_message).and_return('FULL_MESSAGE')
          # allow(logger).to receive(:error)
        end

        context 'and scheduling the retry succeeds' do
          before do
            allow(adapter).to receive(:deliver_message)
            allow(consumer).to receive(:mark_message_as_processed)
          end

          it { is_expected.to eq(true) }

          it 'schedules the retry' do
            expect(adapter).to receive(:deliver_message).with(message.value, topic: topics.last)
            subject
          end

          #
          # it 'logs the error' do
          #   expect(logger).to receive(:error)
          #   subject
          # end
        end

        context 'but scheduling the retry fails' do
          let(:error) { StandardError.new }

          before do
            allow(adapter).to receive(:deliver_message).and_raise(error)
            allow(error).to receive(:full_message).and_return('FULL_MESSAGE')
          end

          it { is_expected.to eq(false) }

          it 'schedules the retry' do
            expect(adapter).to receive(:deliver_message).with(message.value, topic: topics.last)
            subject
          end
          #
          # it 'logs the error' do
          #   expect(logger).to receive(:error).with(error.full_message)
          #   subject
          # end
        end
      end
    end
  end
end
