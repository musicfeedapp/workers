use Mix.Config

config :redis_poolex,
  reconnect: :no_reconnect,
  max_queue: :infinity,
  pool_size: 10,
  pool_max_overflow: 1,
  connection_string: "redis://redis:6379/"

config :logger, level: :error, backends: [:console]

config :requesters, Requesters.Queue.RabbitConfig,
  hostname: "amqp://guest:guest@rabbitmq:5672",
  pool_size: 1,
  max_overflow: 1,
  reconnect_timeout: 5000

config :requesters, Requesters.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: "postgres://postgres:mysecretpassword@db:5432/postgres"

config :tirexs, :uri, "http://elasticsearch:9200"

config :requesters,
  environment: :test,
  pages_workers_size: 1,
  users_workers_size: 1,
  timelines_size: 1,
  aggregator_pages_size: 1,
  aggregator_users_size: 1
