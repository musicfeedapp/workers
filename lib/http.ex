defmodule Requesters.Http do
  use Retry

  require Logger
  require Poison

  alias HTTPoison.Response
  alias HTTPoison.Error

  @http_options [follow_redirect: true, recv_timeout: 50000, timeout: 10000, hackney: [timeout: 10000, pool: false, insecure: true]]

  def get(url) do
    retry 1 in 500 * Enum.random(1..5) do
      _get(url)
    end
  end

  def get_raw(url) do
    retry 1 in 500 * Enum.random(1..5) do
      _get_raw(url)
    end
  end

  def head(url) do
    retry 1 in 500 * Enum.random(1..5) do
      _head(url)
    end
  end

  defp _head(url) do
    case HTTPoison.head(url, [], @http_options) do
      {:ok, %Response{status_code: 200}} -> :ok
      {:ok, %Response{status_code: status_code}} ->
        {:error, "[Http.get] status: #{status_code}, url: #{inspect(url)}"}
      {:error, %Error{reason: reason}} ->
        {:error, "[Http.get] reason: #{inspect(reason)}, url: #{inspect(url)}"}
      _ ->
        {:error, "[Http.get] 0xDEADBEEF happened, url: #{inspect(url)}"}
    end
  end

  defp _get(url) do
    case HTTPoison.get(url, [], @http_options) do
      {:ok, %Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, _value} = state -> state
          error -> {:error, "[Http.get] error: #{inspect(error)}, url: #{inspect(url)}"}
        end
      {:ok, %Response{status_code: 404}} ->
        {:error, "[Http.get] not found resource, url: #{inspect(url)}"}
      {:ok, %Response{status_code: status_code, body: body}} ->
        case Poison.decode(body) do
          {:ok, value} -> {:error, "[Http.get] status: #{status_code}, value: #{inspect(value)}, url: #{inspect(url)}"}
          error -> {:error, "[Http.get] status: #{status_code}, error: #{inspect(error)}, url: #{inspect(url)}"}
        end
      {:error, %Error{reason: reason}} ->
        {:error, "[Http.get] reason: #{inspect(reason)}, url: #{inspect(url)}"}
      _ ->
        {:error, "[Http.get] 0xDEADBEEF happened url: #{inspect(url)}"}
    end
  end

  defp _get_raw(url) do
    case HTTPoison.get(url, [], @http_options) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %Response{status_code: status_code}} ->
        {:error, "[Http.get] status: #{status_code}, url: #{inspect(url)}"}
      {:error, %Error{reason: reason}} ->
        {:error, "[Http.get] reason: #{inspect(reason)}, url: #{inspect(url)}"}
      _ ->
        {:error, "[Http.get] 0xDEADBEEF happened, url: #{inspect(url)}"}
    end
  end
end
