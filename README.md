TopicProxyBackend
=================

A simple proxy for different Logger backends which allows to filter messages based on metadata.

## Configuration

Our config.exs would have an entry similar to this:

```config
# tell logger to load a TopicProxyBackend processes
config :logger, backends: [
  {TopicProxyBackend, :error_log},
  {TopicProxyBackend, :warn_console}
]

# configuration for the {TopicProxyBackend, :error_log} backend
config :logger, :error_log,
  level: :error,
  backend: {
    LoggerFileBackend,
    [path: "log/errors.log"]
  }

# configuration for the {TopicProxyBackend, :warn_console} backend
config :logger, :warn_console,
  level: :warn,
  backend: {
    :console, [
      format: "$time $metadata[$level] $message\n",
      metadata: [:request_id, :time, :retry]
    ]
  }
```

## Usage

Use `:topic` in Logger metadata to write message to appropriate log:

```code
Logger.warn("Some warning", topic: :warn_console)
Logger.error("Error", topic: :error)
```
