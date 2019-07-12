# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Producer do
  class TestProducer < Super::Flux::Producer
    topic 'test'
    max_buffer_size 1000
  end

  describe '#produce' do
    let(:instance) { TestProducer.new }
    subject { instance.produce(message, options) }

    let(:message) { double }
    let(:options) { {} }
    let(:producer) { double }
    let(:buffer) { double }
    let(:flusher) { double }

    before do
      allow(Super::Flux).to receive(:producer).and_return(producer)
      allow(Super::Flux::Producer::Buffer).to receive(:new).and_return(buffer)
      allow(Super::Flux::Producer::Flusher).to receive(:new).and_return(flusher)
      allow(buffer).to receive(:push)
    end

    it 'buffers the message' do
      expect(buffer).to receive(:push).with(message, topic: 'test')
      subject
    end

    it 'sets up the delivery buffer' do
      expect(Super::Flux::Producer::Buffer).to receive(:new)
        .with(producer, max_size: 1000)

      subject
    end

    it 'sets up the delivery flusher' do
      expect(Super::Flux::Producer::Flusher).to receive(:new)
        .with(buffer)

      subject
    end
  end
end
