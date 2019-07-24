# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Reactor::TopicManager do
  let(:instance) { described_class.new(settings) }
  let(:settings) { double(retries: 1) }
  let(:topics) { %w[TOPIC TOPIC-try-1 TOPIC-dlq] }

  before do
    Super::Flux::Reactor::TopicNameFactory.tap do |klass|
      allow(klass).to receive(:call).with(settings, 0).and_return('TOPIC')
      allow(klass).to receive(:call).with(settings, 1).and_return('TOPIC-try-1')
      allow(klass).to receive(:call).with(settings, 2).and_return('TOPIC-dlq')
    end
  end

  describe '#stage_for' do
    subject { instance.stage_for(topic) }

    context 'when requesting the main topic' do
      let(:topic) { 'TOPIC' }

      it { is_expected.to eq(0) }
    end

    context 'when requesting the retry topic' do
      let(:topic) { 'TOPIC-try-1' }

      it { is_expected.to eq(1) }
    end

    context 'when requesting the DLQ topic' do
      let(:topic) { 'TOPIC-dlq' }

      it { is_expected.to eq(2) }
    end
  end

  describe '#next_topic_for' do
    subject { instance.next_topic_for(topic) }

    context 'when requesting the stage after the main topic' do
      let(:topic) { 'TOPIC' }

      it { is_expected.to eq('TOPIC-try-1') }
    end

    context 'when requesting the stage after the retry topic' do
      let(:topic) { 'TOPIC-try-1' }

      it { is_expected.to eq('TOPIC-dlq') }
    end

    context 'when requesting the stage after the DLQ topic' do
      let(:topic) { 'TOPIC-dlq' }

      it { is_expected.to eq(nil) }
    end
  end
end
