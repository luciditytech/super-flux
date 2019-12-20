# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Worker::ResourceMapFactory do
  describe '.call' do
    subject { described_class.call(stages: stages, kafka: kafka_settings, task: task) }

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
    let(:kafka_settings) { double }
    let(:adapters) { [double, double] }
    let(:consumers) { [double, double] }

    let(:expected_result) do
      {
        'TOPIC' => {
          consumer: consumers[0]
        },
        'TOPIC-try-1' => {
          consumer: consumers[1]
        }
      }
    end

    before do
      allow(task).to receive(:settings).and_return(task_settings)
      allow(task).to receive(:topics).and_return(task_topics)
      allow(Kafka).to receive(:new).and_return(adapters[0]).and_return(adapters[1])

      i = 0
      allow(Kafka).to receive(:new) do
        res = adapters[i]
        i += 1
        res
      end

      allow(adapters[0]).to receive(:consumer).and_return(consumers[0])
      allow(adapters[1]).to receive(:consumer).and_return(consumers[1])
    end

    it 'returns the expected map' do
      expect(subject).to match(expected_result)
    end
  end
end
