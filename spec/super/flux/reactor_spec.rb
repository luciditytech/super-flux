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

    before do
      allow(Super::Flux).to receive(:consumer).and_return(consumer)
      allow(task).to receive(:settings).and_return(settings)
      allow(consumer).to receive(:subscribe)
      allow(consumer).to receive(:each_message).and_yield(message)

      allow(Super::Flux::Reactor::TopicFactory).to receive(:call) do |_, stage|
        topics[stage]
      end

      allow(Super::Flux::Governor).to receive(:call)
      allow(Super::Flux::ExecuteTask).to receive(:call).and_return(true)
    end

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
  end
end
