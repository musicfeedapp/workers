defmodule Aggregator.Workers.BaseWorkerServer do
  use GenServer

  require AMQP
  require Logger

  alias Aggregator.Workers.BaseWorker

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:perform, access_token, object_id, who, options, pid}, state)  do
    BaseWorker.perform({access_token, object_id, who, options, pid})
    continue(state)
  end

  def handle_cast({:inc, value}, %{counter: counter} = state) do
    counter = counter + value

    Logger.debug "COUNTER INC CONTINUE counter: #{inspect(counter)}, pid: #{inspect(self())}"

    continue(%{state | counter: counter})
  end

  def handle_cast(:dec,  %{counter: counter} = state) do
    counter = counter - 1

    Logger.debug "COUNTER counter: #{inspect(counter)}, pid: #{inspect(self())}"

    if counter <= 0 do
      Logger.debug "COUNTER DONE counter: #{inspect(counter)}, pid: #{inspect(self())}"
      done(state)
    else
      Logger.debug "COUNTER DEC CONTINUE counter: #{inspect(counter)}, pid: #{inspect(self())}"
      continue(%{state | counter: counter})
    end
  end

  def handle_info({:DOWN, _ref, _type, _pid, _info}, state), do: done(state)
  def handle_info({:EXIT, _pid, _}, state), do: done(state)
  def handle_info(:done, state), do: done(state)

  def continue(state), do: {:noreply, state}

  def done(state) do
    Process.exit(self(), :normal)
    {:noreply, state}
  end
end
