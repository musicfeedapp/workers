defmodule Aggregator.Workers.StorageWorker.StorageSupervisor do
  @moduledoc """
  Supervisor for storing timelines in the database
  """
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    import Supervisor.Spec, warn: false

    children = []

    timelines_size = Application.get_env(:requesters, :timelines_size)

    pool_options = [
      {:name, {:local, :storage_worker_pool}},
      {:worker_module, Aggregator.Workers.StorageWorker.TimelineServer},
      {:size, timelines_size},
      {:max_overflow, 0}
    ]
    children = children ++ [
      :poolboy.child_spec(:storage_worker_pool, pool_options, [])
    ]

    children = children ++ [
      worker(Aggregator.Workers.StorageWorker.ElasticServer, []),
    ]

    supervise(children, [strategy: :one_for_one, name: __MODULE__])
  end

  def perform(timeline) do
    :poolboy.transaction(:storage_worker_pool, fn(worker) ->
      GenServer.call(worker, {:perform, :timeline, timeline})
    end, 300_000)
  end
end
