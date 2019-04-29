defmodule Aggregator.Workers.BaseWorkerServerWrapper do
  use GenServer

  require AMQP
  require Logger

  alias AMQP.Basic

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(state) do
    state = state
        |> Enum.into(%{})
        |> Map.put(:pids, %{})

    Process.flag(:trap_exit, true)

    {:ok, state}
  end

  def handle_cast({:perform, attributes, chan, receiver}, %{pids: pids} = state) do
    Logger.debug "[MAIN PERFORM] RUN PERFORM PID: #{inspect(self())}"

    %{"access_token" => access_token, "object_id" => object_id, "who" => who, "options" => options} = attributes

    {:ok, pid} = Aggregator.Workers.BaseWorkerServer.start_link(%{counter: 0, chan: chan})
    Process.monitor(pid)
    GenServer.cast(pid, {:perform, access_token, object_id, who, options, pid})

    pids = Map.put(pids, pid, %{chan: chan, receiver: receiver})

    {:noreply, %{state | pids: pids}}
  end

  def handle_info({:DOWN, _ref, _type, pid, _info}, state), do: handle_done(pid, state)
  def handle_info({:EXIT, pid, _}, state), do: handle_done(pid, state)

  def handle_cast({:done, pid}, state), do: handle_done(pid, state)

  def handle_done(pid, %{pids: pids} = state) do
    case Map.pop(pids, pid) do
      {%{chan: chan, receiver: receiver}, pids}->
        state = %{state | pids: pids}
        done(state, {chan, receiver})
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end


  def terminate(reason, %{pool: pool, pids: pids}) do
    Logger.error("[BASE_WORKER_SERVER_WRAPPER] reason: #{inspect(reason)}")

    for {_, %{chan: {channel, tag, _}, receiver: receiver}} <- pids do
      Basic.ack(channel, tag)
      send receiver, :ok
    end

    Logger.debug "[BASE_WORKER_SERVER_WRAPPER] DONE receiver: #{inspect(self())}, server pid: #{inspect(self())}"

    :normal
  end
  def terminate(reason, _state) do
    Logger.debug "[BASE_WORKER_SERVER_WRAPPER] TERMINATE 2 REASON: #{inspect(reason)}"
    :normal
  end


  def done(%{pool: pool}, {{channel, tag, _redelivered}, receiver}) do
    Basic.ack(channel, tag)
    Logger.debug "[BASE_WORKER_SERVER_WRAPPER] DONE receiver: #{inspect(self())}, server: #{inspect(self())}, tag: #{inspect(tag)}"
    send receiver, :ok
  end
end
