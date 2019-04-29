defmodule Requesters.Queue.RabbitSupervisor do
  require Logger

  @moduledoc """
  Supervisor for starting each separate gen server for channels of rabbitmq
  """
  use Supervisor

  def start_link(state) do
    Supervisor.start_link(__MODULE__, state)
  end

  def init({pool, size}) do
    name = "#{pool}_amqp" |> String.to_atom

    pool_options = [
      {:name, {:local, name}},
      {:worker_module, Requesters.Queue.RabbitConnectionWorker},
      {:size, size},
      {:max_overflow, size}
    ]

    children = [
      :poolboy.child_spec(
        name,
        pool_options,
        {pool, size}
    )]

    supervise(children, strategy: :one_for_one)
  end
end
