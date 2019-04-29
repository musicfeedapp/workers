defmodule Aggregator.Workers.StorageWorker.TimelineServer do
  use GenServer
  use Timex

  require Logger

  alias RedisPoolex, as: Redis
  alias Queries.Timelines
  alias Queries.TimelinePublishers
  alias Queries.Users
  alias Queries.Comments
  alias Aggregator.Workers.StorageWorker.ElasticServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(_opts) do
    {:ok, nil}
  end

  def handle_call({:perform, :timeline, timeline}, from, state) do
    try do
      store!(timeline)
      Logger.debug "TimelineServer store! #{inspect(timeline)}"
    rescue
      exception ->
        Logger.debug("[StorageWorker.TimelineServer] error: #{inspect(exception)}")
    end

    {:reply, from, state}
  end

  def store!(t) do
    # Lets mark facebook feed as processed for skipping it in the future
    # reprocessing methods.
    Redis.query(["SET", "ps:#{t.identifier}", true])

    t
    |> ok
    |> exists_timeline?
    |> update_timeline(t)
    |> create_timeline(t)
    |> create_comments(t)
    |> create_publishers(t)
    |> create_elastic
    |> logger_error
  end


  def logger_error({:error, error}), do: Logger.debug(inspect(error))
  def logger_error({:repo_error, error}), do: Logger.debug(inspect(error))
  def logger_error(s), do: s

  def ok(t), do: {:ok, t}

  def exists_timeline?({:ok, t}), do: Timelines.exists?(t)

  def update_timeline({:error, _error} = s, _), do: s
  def update_timeline({:repo_error, _error} = s, _), do: s
  def update_timeline({:ok, exists}, t), do: Timelines.update(exists, t)

  def create_timeline({:ok, _exists} = s, _), do: s
  def create_timeline({:repo_error, _error} = s, _), do: s
  def create_timeline({:error, _error}, t), do: Timelines.create_by(t)

  def create_comments({:error, _error} = s), do: s
  def create_comments({:repo_error, _error} = s), do: s
  def create_comments({:ok, timeline}, t) do
    users = t |> Users.all

    # TODO:
    #
    # 1. Add constraint or transaction block ensure to have only unique comments
    # here. because of having duplicates in case of parallel processing
    # of timelines.
    users
    |> Enum.with_index
    |> Enum.each(fn({user, index}) ->
      Comments.create_by(%{timeline: timeline, user: user, t: t, index: index})
    end)

    {:ok, timeline}
  end

  def create_publishers({:error, _error} = s, _), do: s
  def create_publishers({:repo_error, _error} = s, _), do: s
  def create_publishers({:ok, timeline}, t), do: TimelinePublishers.create(timeline, t)

  def create_elastic({:error, _} = s), do: s
  def create_elastic({:repo_error, _} = s), do: s
  def create_elastic({:ok, timeline} = s) do
    ElasticServer.index(timeline)
    s
  end
end
