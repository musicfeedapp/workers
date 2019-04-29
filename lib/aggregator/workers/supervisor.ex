defmodule Aggregator.Workers.Supervisor do
  require Logger

  @moduledoc """
  Supervisor for starting and handling all workers in the requesters module.
  """
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = []

    pages_size = Application.get_env(:requesters, :aggregator_pages_size)
    pages_processor_size = Application.get_env(:requesters, :aggregator_pages_processor_size)
    children = if pages_size > 0 do
      pool_options1 = [
        {:name, {:local, :base_worker_pages_pool}},
        {:worker_module, Aggregator.Workers.BaseWorkerServerWrapper},
        {:size, pages_size},
        {:max_overflow, 0}
      ]
      pool_options2 = [
        {:name, {:local, :base_worker_processor_pages_pool}},
        {:worker_module, Aggregator.Workers.BaseWorkerProcessorWrapperServer},
        {:size, pages_processor_size},
        {:max_overflow, 0}
      ]

      children ++ [
        :poolboy.child_spec(:base_worker_pages_pool, pool_options1, [{:pool, :base_worker_pages_pool}])
      ] ++ [
        :poolboy.child_spec(:base_worker_processor_pages_pool, pool_options2, [])
      ]
    else
      children
    end


    users_size = Application.get_env(:requesters, :aggregator_users_size)
    users_processor_size = Application.get_env(:requesters, :aggregator_users_processor_size)
    children = if users_size > 0 do
      pool_options1 = [
        {:name, {:local, :base_worker_users_pool}},
        {:worker_module, Aggregator.Workers.BaseWorkerServerWrapper},
        {:size, users_size},
        {:max_overflow, 0}
      ]
      pool_options2 = [
        {:name, {:local, :base_worker_processor_users_pool}},
        {:worker_module, Aggregator.Workers.BaseWorkerProcessorWrapperServer},
        {:size, users_processor_size},
        {:max_overflow, 0}
      ]
      children ++ [
        :poolboy.child_spec(:base_worker_users_pool, pool_options1, [{:pool, :base_worker_users_pool}])
      ] ++ [
        :poolboy.child_spec(:base_worker_processor_users_pool, pool_options2, [])
      ]
    else
      children
    end

    children = children ++ [
      supervisor(Aggregator.Workers.StorageWorker.StorageSupervisor, []),
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end

  @doc """
  When we need to make requests to facebook for user we should use authentication by encrypting
  secret key and access_token.

  Running from Rabbit channel worker, find method is generic method to call `consumer_module`
  """
  def find(attributes, "pages.aggregator", chan) do
    %{"options" => options} = attributes
    attributes = Map.put(attributes, "options", Map.merge(options, %{"requires_auth" => false, "processor" => :base_worker_processor_pages_pool}))

    :poolboy.transaction(:base_worker_pages_pool, fn(worker) ->
      GenServer.cast(worker, {:perform, attributes, chan, self()})

      # block until we receive response
      receive do
        :ok -> Logger.debug("received done on processing attributes in pool, #{inspect(self())}")
        _ -> Logger.error("issue on working on processing attributes in pool")
      end
    end, 500_000)
  end

  def find(attributes, "users.aggregator", chan) do
    %{"options" => options} = attributes
    attributes = Map.put(attributes, "options", Map.merge(options, %{"requires_auth" => true, "processor" => :base_worker_processor_users_pool}))

    :poolboy.transaction(:base_worker_users_pool, fn(worker) ->
      GenServer.cast(worker, {:perform, attributes, chan, self()})

      # block until we receive response
      receive do
        :ok -> Logger.debug("received done on processing attributes in pool, #{inspect(self())}")
        _ -> Logger.error("issue on working on processing attributes in pool")
      end
    end, 500_000)
  end
end
