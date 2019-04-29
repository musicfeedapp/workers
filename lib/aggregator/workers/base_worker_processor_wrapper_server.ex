defmodule Aggregator.Workers.BaseWorkerProcessorWrapperServer do
  use GenServer

  alias Aggregator.Workers.BaseWorkerProcessorServer

  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(_opts) do
    {:ok, %{pids: %{}}}
  end

  # base_worker_processor_pages_pool
  # base_worker_processor_users_pool
  def handle_call({:process, attributes, access_token, _, options, pid}, from, %{pids: pids} = state) do
    child = spawn fn ->
      BaseWorkerProcessorServer.process({attributes, access_token, options, pid})
    end
    Process.monitor(child)

    pids = Map.put(pids, child, %{pid: pid})

    {:reply, from, %{state | pids: pids}}
  end

  def handle_info({:DOWN, _ref, _type, pid, _info}, state), do: handle_done(pid, state)
  def handle_info({:EXIT, pid, _}, state), do: handle_done(pid, state)

  def terminate(reason, %{pids: pids} = state) do
    Logger.debug "[BASE_WORKER_PROCESSOR_WRAPPER_SERVER] reason: #{inspect(reason)}, state: #{inspect(state)}"

    for {_, %{pid: pid}} <- pids do
      GenServer.cast(pid, :dec)
    end

    :normal
  end

  def handle_done(child, %{pids: pids} = state) do
    case Map.pop(pids, child) do
      {%{pid: pid}, pids}->
        GenServer.cast(pid, :dec)
        {:noreply, %{state | pids: pids}}
      _ ->
        {:noreply, state}
    end
  end
end
