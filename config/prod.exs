use Mix.Config

config :redis_poolex,
  host: "104.131.232.47",
  port: 6379,
  password: "",
  db: 0,
  reconnect: :no_reconnect,
  max_queue: :infinity,
  pool_size: 40,
  pool_max_overflow: 80,
  timeout: 20000

config :logger, level: :error

config :requesters, Requesters.Queue.RabbitConfig,
  hostname: "amqp://feedler:feedler@192.241.163.72:5672",
  pool_size: 1,
  max_overflow: 1,
  reconnect_timeout: 5000

config :requesters, Requesters.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: "162.243.68.200",
  port: "6432",
  database: "feedler",
  username: "feedler",
  password: "201287ali",
  pool_size: 5,
  timeout: 50000

config :requesters,
  environment: :prod,
  pages_workers_size: 70,
  users_workers_size: 15,
  timelines_size: 10,
  aggregator_pages_size: 70,
  aggregator_pages_processor_size: 70,
  aggregator_users_size: 15,
  aggregator_users_processor_size: 15

config :tirexs, :uri, "http://192.241.179.172:9200"
