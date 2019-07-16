# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Reactor::TopicNameFactory do
  describe '.call' do
    subject { described_class.call(settings, stage) }
    let(:settings) { double(topic: 'TOPIC', retries: 2, group_id: 'GROUP') }

    context 'when stage is 0' do
      let(:stage) { 0 }

      it { is_expected.to eq('TOPIC') }
    end

    context 'when it\'s a middle stage' do
      let(:stage) { 1 }

      it { is_expected.to eq('TOPIC-GROUP-try-1') }
    end

    context 'when it\'s the last stage' do
      let(:stage) { 3 }

      it { is_expected.to eq('TOPIC-GROUP-dlq') }
    end
  end
end
