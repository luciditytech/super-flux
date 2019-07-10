# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Governor do
  describe '.call' do
    subject { described_class.call(message, stage) }

    let(:message) { double }
    let(:consumer) { double }
    let(:stage) { double }

    before do
      allow(Super::Flux).to receive(:consumer).and_return(consumer)
    end

    context 'when stage is 0' do
      let(:stage) { 0 }

      it { is_expected.to be_nil }
    end

    context 'when stage is not 0' do
      let(:stage) { 5 }

      context 'and the message is not early' do
        before do
          allow(message).to receive(:create_time).and_return(Time.now.utc - 7200)
        end

        it { is_expected.to be_nil }
      end

      context 'and the message is early' do
        before do
          allow(message).to receive(:create_time).and_return(Time.now.utc - 1)
          allow(message).to receive(:topic).and_return('TOPIC')
          allow(message).to receive(:partition).and_return(1)
          allow(consumer).to receive(:pause)
        end

        it 'pauses the partition consumption' do
          expect(consumer).to receive(:pause)
            .with('TOPIC', 1, timeout: an_instance_of(Integer))

          subject
        end
      end
    end
  end
end
