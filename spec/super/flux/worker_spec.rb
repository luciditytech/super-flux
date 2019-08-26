# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Super::Flux::Worker do
  TOPICS = %w[TOPIC TOPIC-try-1 TOPIC-dlq].freeze

  let(:instance) { described_class.new(**params) }

  describe '#start' do
    let(:topics) { TOPICS }
    let(:task) { double }
    let(:logger) { double }
    let(:stages) { Range.new(0, 1) }
    let(:kafka_options) { double }

    let(:params) do
      {
        task: task,
        logger: logger,
        stages: stages,
        options: {
          kafka: kafka_options,
          run_once: true
        }
      }
    end

    let(:resource_map) do
      {
        'TOPIC' => { adapter: double, consumer: double },
        'TOPIC-try-1' => { adapter: double, consumer: double }
      }
    end

    let(:reactors) { [main_reactor, secondary_reactor] }
    let(:main_reactor) { double }
    let(:secondary_reactor) { double }

    subject { instance.start }

    before do
      allow(logger).to receive(:info)
      allow(Super::Flux::Worker::ResourceMapFactory).to receive(:call).and_return(resource_map)

      allow(Super::Flux::Worker::ReactorFactory).to receive(:call).with(
        task: task,
        logger: logger,
        topic: 'TOPIC',
        options: params[:options],
        adapter: resource_map['TOPIC'][:adapter],
        consumer: resource_map['TOPIC'][:consumer]
      ).and_return(main_reactor)

      allow(Super::Flux::Worker::ReactorFactory).to receive(:call).with(
        task: task,
        logger: logger,
        topic: 'TOPIC-try-1',
        options: params[:options],
        adapter: resource_map['TOPIC-try-1'][:adapter],
        consumer: resource_map['TOPIC-try-1'][:consumer]
      ).and_return(secondary_reactor)

      allow(main_reactor).to receive(:start)
      allow(secondary_reactor).to receive(:start)
    end

    it 'setups up the resource map' do
      expect(Super::Flux::Worker::ResourceMapFactory).to receive(:call).with(
        stages: stages,
        task: task,
        kafka: kafka_options
      )

      subject
    end

    it 'starts the main reactor' do
      expect(main_reactor).to receive(:start)
      subject
    end

    it 'starts the secondary reactor' do
      expect(secondary_reactor).to receive(:start)
      subject
    end
  end
end
