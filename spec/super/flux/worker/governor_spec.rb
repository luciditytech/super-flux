# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Worker::Governor do
  describe '.call' do
    subject { described_class.call(message, stage) }

    let(:message) { double }
    let(:stage) { double }

    context 'when stage is 0' do
      let(:stage) { 0 }

      it { is_expected.to eq(false) }
    end

    context 'when stage is not 0' do
      let(:stage) { 5 }

      context 'and the message is not early' do
        before do
          allow(message).to receive(:create_time).and_return(Time.now.utc - 7200)
        end

        it { is_expected.to eq(false) }
      end

      context 'and the message is early' do
        before do
          allow(message).to receive(:create_time).and_return(Time.now.utc - 1)
        end

        it { is_expected.to eq(true) }
      end
    end
  end
end
