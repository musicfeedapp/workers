defmodule Requesters.Queue.RabbitConfig do
  def pool_size do
    Application.get_env(:requesters, __MODULE__)[:pool_size] || 1
  end

  def max_overflow do
    Application.get_env(:requesters, __MODULE__)[:max_overflow] || 1
  end

  def host do
    Application.get_env(:requesters, __MODULE__)[:hostname] || "127.0.0.1"
  end

  def reconnect_timeout do
    Application.get_env(:requesters, __MODULE__)[:reconnect_timeout] || 5000
  end

  def prefetch_count do
    Application.get_env(:requesters, __MODULE__)[:prefetch_count] || 1
  end
end
