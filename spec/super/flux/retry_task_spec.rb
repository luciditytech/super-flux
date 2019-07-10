# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::RetryTask do
  describe '.call' do
    subject { described_class.call(message, next_topic) }
    let(:adapter) { double }
    let(:consumer) { double }
    let(:message) { double(value: 'VALUE') }
    let(:next_topic) { 'NEXT' }

    around do |example|
      original = Super::Flux.configuration.adapter
      Super::Flux.configuration.adapter = adapter
      example.run
      Super::Flux.configuration.adapter = original
    end

    before do
      allow(Super::Flux).to receive(:consumer).and_return(consumer)
    end

    context 'when the delivery is successful' do
      before do
        allow(adapter).to receive(:deliver_message)
        allow(consumer).to receive(:mark_message_as_processed)
      end

      it { is_expected.to eq(true) }

      it 'delivers the message to the retry topic' do
        expect(adapter).to receive(:deliver_message).with('VALUE', topic: 'NEXT')
        subject
      end

      it 'marks the message as processed' do
        expect(consumer).to receive(:mark_message_as_processed).with(message)
        subject
      end
    end

    context 'when the delivery is not successful' do
      before do
        allow(adapter).to receive(:deliver_message).and_raise(StandardError.new)
      end

      it { is_expected.to eq(false) }
    end
  end
end
