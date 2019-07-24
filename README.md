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

Tasks are processed by instantiating reactors:

```ruby
#!/usr/bin/env ruby

require_relative '../config/boot'

task = Kernel.const_get(ARGV[0])
Super::Flux.run(task)
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
