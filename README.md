TopicProxyBackend
=================

A simple proxy for different Logger backends which allows to filter messages based on metadata.

## Configuration

Our config.exs would have an entry similar to this:

```config
# tell logger to load a TopicProxyBackend processes
config :logger, backends: [
  {TopicProxyBackend, :error_log},
  {TopicProxyBackend, :graylog}
]

# configuration for the {TopicProxyBackend, :error_log} backend
config :logger, :error_log,
  level: :error,
  backend: {
    LoggerFileBackend,
    [path: "log/errors.log"]
  }

# configuration for the {TopicProxyBackend, :graylog} backend
config :logger, :graylog,
  level: :info,
  backend: {
    Logger.Backends.Gelf, [
      host: "graylog.example.com",
      port: 12201,
      application: "MyApplication",
      compression: :gzip,
      metadata: [:request_id, :function, :module, :file, :line]
    ]
  }
```

## Usage

Use `:topic` in Logger metadata to write message to appropriate log:

```code
Logger.info("Info", topic: :graylog)
Logger.error("Error", topic: :error_log)
```

Do not use it for `:console` backend.
