# Super::Flux

`Super::Flux` is a high performance framework for creating producers and consumers using Kafka. It's intended to be used with the `Super` toolchain but it can be used separately in any application.

## Installation

```ruby
# Gemfile
gem 'super-flux'
```

If you want to add compression (ex: lz4), make sure to add any dependencies to your Gemfile. Example:

```ruby
gem 'extlz4'
```

## Setup

`Super::Flux` allows you to set global Kafka adapter and producer options so that you don't have to manually set up everything. If you need to use custom adapters (ex: if you using multiple Kafka clusters), you may do so by injecting those directly into the classes you wish to customize.

```ruby
# config/initializers/super-flux.rb

Super::Flux.configure do |config|
  config.kafka = {
    brokers: Settings.kafka.brokers,
    client_id: Settings.kafka.client_id
  }

  config.producer_options = {
    max_buffer_size: Settings.kafka.max_buffer_size,
    compression_codec: Settings.kafka.compression_codec,
    required_acks: Settings.kafka.required_acks
  }.compact
end
```

## Usage

### Producers

`Super::Flux` provides an easy to use and extensive framework for creating topic-specific producers. These auto-boot when first used in a thread safe way and automatically flush pending messages both regularly and if the internal buffer overloads.

```ruby
class AwesomeProducer
  include Super::Flux::Producer

  topic 'awesome'
end

AwesomeProducer.produce('MESSAGE', partition_key: 'KEY')
```

### Consumers
`Super::Flux` provides an easy way to define tasks that process Kafka messages. Furthermore, retries are automatically processed using multiple retry topics. Reference: [Building Reliable Reprocessing and Dead Letter Queues with Apache Kafka](https://eng.uber.com/reliable-reprocessing/).

```ruby
# app/kafka/awesome_task.rb

class AwesomeTask
  include Super::Flux::Task

  topic 'awesome' # input topic
  group_id 'magnificent-5' # Consumer Group
  retries 5 # maximum number of retries

  def call(message)
    Super::Flux.logger.info(message)
  end
end
```

Example usage for a simple task with 5 retries (6 stages including the Dead Letter Queue):

Running the main stage:
```
$ bundle exec flux process --load ./config/boot.rb --stages 0 AwesomeTask
```

Running retry stages:
```
$ bundle exec flux process --load ./config/boot.rb --stages 1-6 AwesomeTask
```

Running all stages:
```
$ bundle exec flux process --load ./config/boot.rb AwesomeTask
```

NOTE: For high throughput applications you should consider running the main stage and the retry stages separately. The main stage is not throttled so this allows for maximum consumption speed.

#### Retries
By default an exponential backoff strategy will be used to throttle retries. The approximate wait times are:

```
Stage #1: ~45 seconds wait time
Stage #2: ~1.2 minutes wait time, ~2.0 minutes total wait time
Stage #3: ~2.6 minutes wait time, ~4.5 minutes total wait time
Stage #4: ~5.7 minutes wait time, ~10.2 minutes total wait time
Stage #5: ~12.1 minutes wait time, ~22.4 minutes total wait time
Stage #6: ~23.5 minutes wait time, ~45.9 minutes total wait time
Stage #7: ~42.2 minutes wait time, ~1.5 hours total wait time
Stage #8: ~1.2 hours wait time, ~2.6 hours total wait time
Stage #9: ~1.9 hours wait time, ~4.5 hours total wait time
Stage #10: ~2.8 hours wait time, ~7.3 hours total wait time
Stage #11: ~4.1 hours wait time, ~11.5 hours total wait time
Stage #12: ~5.8 hours wait time, ~17.3 hours total wait time
Stage #13: ~8.0 hours wait time, ~1.1 days total wait time
Stage #14: ~10.7 hours wait time, ~1.5 days total wait time
Stage #15: ~14.1 hours wait time, ~2.1 days total wait time
Stage #16: ~18.3 hours wait time, ~2.9 days total wait time
Stage #17: ~23.3 hours wait time, ~3.8 days total wait time
Stage #18: ~1.2 days wait time, ~5.0 days total wait time
Stage #19: ~1.5 days wait time, ~6.6 days total wait time
Stage #20: ~1.9 days wait time, ~8.4 days total wait time
Stage #21: ~2.3 days wait time, ~10.7 days total wait time
Stage #22: ~2.7 days wait time, ~13.4 days total wait time
Stage #23: ~3.2 days wait time, ~16.6 days total wait time
Stage #24: ~3.8 days wait time, ~20.5 days total wait time
Stage #25: ~4.5 days wait time, ~25.0 days total wait time
```
