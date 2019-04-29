defmodule Requesters.Queue.RabbitConnectionWorker do
  require Logger

  use AMQP
  use GenServer

  alias Requesters.Queue.RabbitConfig

  def start_link(state) do
    :gen_server.start_link(__MODULE__, state, [])
  end

  def init(options) do
    state = %{options: options}

    :erlang.send(self(), {:connect, options})

    {:ok, state}
  end

  def handle_rabbit_connect({:error, _}, %{connection: _connection, channel: channel, options: options} = state, host) do
    Logger.debug("[Rabbit] error on connecting to server: #{inspect(host)}")

    # Requesters.Queue.RabbitChannelWorker.stop(channel)

    :erlang.send_after(RabbitConfig.reconnect_timeout, self(), {:connect, options})
    {:noreply, state}
  end

  def handle_rabbit_connect({:error, _}, %{options: options} = state, host) do
    Logger.debug("[Rabbit] error on connecting to server: #{inspect(host)}")
    :erlang.send_after(RabbitConfig.reconnect_timeout, self(), {:connect, options})
    {:noreply, state}
  end

  def handle_rabbit_connect({:ok, connection}, %{options: {pool, size}} = state, _host) do
    %Connection{pid: pid} = connection
    Process.link(pid)

    {:ok, channel} = Requesters.Queue.RabbitChannelWorker.start_link(connection, %{
          queue: pool,
          exchange: pool,
          error: "#{pool}.error",
          size: size},
      Aggregator.Workers.Supervisor)

    state = state |> Map.put(:connection, connection) |> Map.put(:channel, channel)

    {:noreply, state}
  end

  def handle_info({:connect, _}, %{options: _} = state) do
    host = RabbitConfig.host
    handle_rabbit_connect(Connection.open(host), state, host)
    {:noreply, state}
  end

  def handle_info({:connect, options}, state) do
    host = RabbitConfig.host
    state = Map.put(state, :options, options)
    handle_rabbit_connect(Connection.open(host), state, host)
    {:noreply, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :normal
  end
end
