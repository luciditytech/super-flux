# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::ExecuteTask do
  describe '.call' do
    subject { described_class.call(task, message) }

    let(:task) { double }
    let(:message) { double(value: 'VALUE') }
    let(:consumer) { double }

    before do
      allow(Super::Flux).to receive(:consumer).and_return(consumer)
    end

    context 'when the task executes successfully' do
      before do
        allow(task).to receive(:call)
        allow(consumer).to receive(:mark_message_as_processed)
      end

      it { is_expected.to eq(true) }

      it 'executes the task' do
        expect(task).to receive(:call).with('VALUE')
        subject
      end

      it 'marks the message as processed' do
        expect(consumer).to receive(:mark_message_as_processed).with(message)
        subject
      end
    end

    context 'when the task fails' do
      before do
        allow(task).to receive(:call).and_raise(StandardError.new)
      end

      it { is_expected.to eq(false) }

      it 'attempts to execute the task' do
        expect(task).to receive(:call).with('VALUE')
        subject
      end
    end
  end
end
