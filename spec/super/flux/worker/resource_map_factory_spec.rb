# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Worker::ResourceMapFactory do
  describe '.call' do
    subject { described_class.call(stages: stages, task: task) }

    let(:task) { double }
    let(:stages) { Range.new(0, 1) }
    let(:task) { double }

    let(:task_settings) do
      double(
        group_id: 'GROUP',
        offset_commit_interval: 1,
        offset_commit_threshold: 1000
      )
    end

    let(:task_topics) { %w[TOPIC TOPIC-try-1 TOPIC-dlq] }
    let(:adapter) { double }
    let(:consumer) { double }

    let(:expected_result) do
      {
        'TOPIC' => {
          consumer: consumer
        },
        'TOPIC-try-1' => {
          consumer: consumer
        }
      }
    end

    before do
      allow(task).to receive(:settings).and_return(task_settings)
      allow(task).to receive(:topics).and_return(task_topics)
      allow(Super::Flux).to receive_message_chain(:pool, :with).and_yield(adapter)
      allow(adapter).to receive(:consumer).and_return(consumer)
    end

    it 'returns the expected map' do
      expect(subject).to match(expected_result)
    end
  end
end
