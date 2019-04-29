defmodule Requesters do
  @moduledoc """
  Entire application.
  """
  use Application

  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Requesters.Queue.Supervisor, []),
      supervisor(Aggregator.Workers.Supervisor, []),
      worker(Requesters.Repo, []),
    ]
    # children = []

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

end
