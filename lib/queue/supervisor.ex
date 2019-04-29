defmodule Requesters.Queue.Supervisor do
  require Logger

  @moduledoc """
  Supervisor for starting and handling all workers in the requesters module.
  """
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    import Supervisor.Spec, warn: false

    children = []

    users_size = Application.get_env(:requesters, :users_workers_size)
    children = if users_size > 0 do
      children ++ [
        supervisor(Requesters.Queue.RabbitSupervisor, [{"users.aggregator", users_size}], [id: "users.aggregator", name: "users.aggregator"]),
      ]
    else
      children
    end

    pages_size = Application.get_env(:requesters, :pages_workers_size)
    children = if pages_size > 0 do
      children ++ [
        supervisor(Requesters.Queue.RabbitSupervisor, [{"pages.aggregator", pages_size}], [id: "pages.aggregator", name: "pages.aggregator"]),
      ]
    else
      children
    end

    supervise(children, strategy: :one_for_one)
  end
end
