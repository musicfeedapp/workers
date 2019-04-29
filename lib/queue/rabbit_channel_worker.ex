defmodule Requesters.Queue.RabbitChannelWorker do
  require Logger
  require Poison

  alias Requesters.Queue.RabbitConfig

  use GenServer
  use AMQP

  def start_link(%Connection{pid: pid}, amqp_options, consumer_module) do
    :gen_server.start_link(__MODULE__, %{connection: pid, amqp_options: amqp_options, consumer_module: consumer_module}, [])
  end

  @doc """
  We should pass connection of amqp connection and use it later
  """
  def init(%{connection: pid, amqp_options: %{queue: queue_name, exchange: exchange_name, error: error_name}, consumer_module: consumer_module}) do
    connection = %Connection{pid: pid}

    {:ok, channel} = Channel.open(connection)
    Basic.qos(channel, prefetch_count: RabbitConfig.prefetch_count)

    Queue.declare(channel, error_name, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    Queue.declare(channel, queue_name, durable: true,
                  arguments: [{"x-dead-letter-exchange", :longstr, ""},
                              {"x-dead-letter-routing-key", :longstr, error_name}])
    Exchange.fanout(channel, exchange_name)
    Queue.bind(channel, queue_name, exchange_name)

    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(channel, queue_name)
    {:ok, {channel, queue_name, consumer_module}}
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def handle_call(:stop, _from, status) do
    {:stop, :normal, status}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    parent_pid = self()
    spawn fn -> consume(chan, parent_pid, tag, redelivered, payload) end
    {:noreply, chan}
  end

  def handle_info({:DOWN, _, _, _, _}, _) do
    Logger.debug "CHANNEL DOWN #{self()}"
  end

  def handle_info({:EXIT, _, _}, _) do
    Logger.debug "CHANNEL EXIT #{self()}"
  end

  def terminate(reason, _state) do
    Logger.debug "CHANNEL TERMINATE REASON: #{inspect(reason)}"
    :normal
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  defp consume({channel, queue_name, consumer_module}, parent_pid, tag, redelivered, payload) do
    Logger.debug "[RABBIT] BEGIN TAG: #{inspect(tag)}, channel: #{inspect(channel)}, payload: #{inspect(payload)}"

    try do
      Logger.debug "[RABBIT] tag: #{inspect(tag)}, pid: #{inspect(parent_pid)}"

      # we are publishing messages as json.
      payload
      |> Poison.decode!
      |> consumer_module.find(queue_name, {channel, tag, redelivered})
    rescue
      exception ->
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        Logger.error "[RABBIT] REJECT TAG: #{inspect(tag)}, error: #{inspect(exception)}"
        Basic.reject(channel, tag, requeue: not redelivered)
    end
  end
end
