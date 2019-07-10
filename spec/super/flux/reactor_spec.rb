# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Reactor do
  describe '.start' do
    subject { instance.start }

    let(:instance) { described_class.new(task) }
    let(:task) { double }
    let(:settings) { double(retries: 2, topic: 'TOPIC') }
    let(:topics) { Array.new(4) { double } }
    let(:consumer) { double }
    let(:message) { double(topic: topics.first) }

    shared_examples_for 'a reactor loop' do
      it 'subscribes do all topics' do
        topics[0..-2].each do |topic|
          expect(consumer).to receive(:subscribe).with(topic)
        end

        subject
      end

      it 'throttles the message' do
        expect(Super::Flux::Governor).to receive(:call).with(message, 0)
        subject
      end

      it 'executes the task' do
        expect(Super::Flux::ExecuteTask).to receive(:call)
          .with(task, message)

        subject
      end
    end

    before do
      allow(Super::Flux).to receive(:consumer).and_return(consumer)
      allow(task).to receive(:settings).and_return(settings)
      allow(consumer).to receive(:subscribe)
      allow(consumer).to receive(:each_message).and_yield(message)

      allow(Super::Flux::Reactor::TopicFactory).to receive(:call) do |_, stage|
        topics[stage]
      end

      allow(Super::Flux::Governor).to receive(:call)
    end

    context 'when the task execution is successful' do
      before do
        allow(Super::Flux::ExecuteTask).to receive(:call).and_return(true)
      end

      it_behaves_like 'a reactor loop'

      it 'does not attempt a retry' do
        expect(Super::Flux::RetryTask).to_not receive(:call)

        subject
      end
    end

    context 'when the task execution fails' do
      before do
        allow(Super::Flux::ExecuteTask).to receive(:call).and_return(false)
        allow(Super::Flux::RetryTask).to receive(:call).and_return(true)
      end

      it_behaves_like 'a reactor loop'

      it 'attempts a retry' do
        expect(Super::Flux::RetryTask).to receive(:call)
          .with(message, topics[1])

        subject
      end
    end
  end
end
