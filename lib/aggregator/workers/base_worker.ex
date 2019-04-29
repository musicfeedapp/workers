defmodule Aggregator.Workers.BaseWorker do
  require Logger

  use Timex

  alias Requesters.Facebook
  alias RedisPoolex, as: Redis

  @fields "id,name,picture,description,link,from,created_time,application,comments.limit(1).summary(true),to,likes.limit(1).summary(true),story_tags"
  @feed_query [:feed, @fields]
  @home_query [:home, @fields]


  # access_token, object_id, who, options, pid
  def perform(args) do
    try do
      collector_for(args)
      |> _perform(args, 0)
      |> done(args)
      |> logger_perform(args)
    rescue
      exception ->
        error = "[BaseWorker] received error: #{inspect(exception)}"
        done({:error, error}, args)
    end
  end


  defp logger_perform({:error, error}, args), do: Logger.debug("[perform] #{inspect(error)}, args: #{inspect(args)}")
  defp logger_perform(s, _args), do: s


  defp _perform({:error, _error} = s, _, _), do: s
  defp _perform({:ok, %{"data" => []}}, _, counter), do: {:ok, counter}
  defp _perform({:ok, %{"data" => collection}} = response, {_, _, _, %{"recent" => false}, _} = args, counter) do
    collection = case run(collection, args) do
      {:ok, collection} -> collection
      {:error, _error} -> []
    end

    _perform(response |> Facebook.next_page, args, counter + Enum.count(collection))
  end
  defp _perform({:ok, %{"data" => collection}}, args, counter) do
    collection = case run(collection, args) do
      {:ok, collection} -> collection
      {:error, _error} -> []
    end

    {:ok, counter + Enum.count(collection)}
  end


  def done({:ok, 0}, {_, _, _, _, pid}) do
    send pid, :done
  end
  def done({:error, error}, {_, _, _, _, pid}) do
    Logger.debug "[BaseWorker] error: #{inspect(error)}"
    send pid, :done
  end
  def done(s, _), do: s


  @doc """
  Run process in separate threads in pools, it would speed up processing.
  """
  def run(collection, {_, object_id, _, _, pid} = args) do
    collection
    |> ok
    |> only_allowed
    |> redis_filter
    |> inc(pid)
    |> run_process(args)
    |> finish(object_id)
  end


  def inc({:error, _error} = s, _), do: s
  def inc({:ok, collection} = s, pid) do
    GenServer.cast(pid, {:inc, Enum.count(collection)})
    s
  end


  def redis_filter({:error, _error} = s), do: s
  def redis_filter({:ok, collection}) do
    # in case if we have already processed the track we should skip it
    collection = collection
                 |> Enum.filter(
                   fn(attributes) ->
                     Redis.query(["GET", "ps:#{attributes["id"]}"]) == :undefined
                   end)
    {:ok, collection}
  end


  def only_allowed({:error, _error} = s), do: s
  def only_allowed({:ok, collection}), do: {:ok, _only_allowed(collection, [])}
  defp _only_allowed([], collector), do: collector
  defp _only_allowed([%{"application" => %{"link" => link}} = head | tail], collector) do
    _only_allowed(tail, _collect_allowed(head, link, collector))
  end
  defp _only_allowed([%{"link" => link} = head | tail], collector) do
    _only_allowed(tail, _collect_allowed(head, link, collector))
  end
  defp _only_allowed([_head | tail], collector), do: _only_allowed(tail, collector)

  def _collect_allowed(head, link, collector) do
    collector = if String.contains?(link, "youtube.com") do
      collector ++ [head]
    else
      collector
    end

    collector = if String.contains?(link, "youtu.be") do
      collector ++ [head]
    else
      collector
    end

    collector = if String.contains?(link, "spotify.com") do
      collector ++ [head]
    else
      collector
    end

    collector = if String.contains?(link, "shazam.com") do
      collector ++ [head]
    else
      collector
    end

    collector = if String.contains?(link, "soundcloud.com") do
      collector ++ [head]
    else
      collector
    end

    collector = if String.contains?(link, "mixcloud.com") do
      collector ++ [head]
    else
      collector
    end

    collector
  end


  def run_process({:ok, collection}, {access_token, object_id, _, options, pid})  do
    # base_worker_processor_pages_pool
    # base_worker_processor_users_pool
    processor = options["processor"]
    options = Map.delete(options, "processor")

    collection
    |> Enum.each(
      fn(attributes) ->
        spawn fn ->
          :poolboy.transaction(processor, fn(worker) ->
            GenServer.call(worker, {:process, attributes, access_token, object_id, options, pid})
          end, 300_000)
        end
      end)

    {:ok, collection}
  end
  def run_process({:error, _error} = s, _args), do: s


  def collector_for({access_token, object_id, "me", options, _pid}) do
    query(access_token, object_id, options, @feed_query)
  end
  def collector_for({access_token, object_id, _who, options, _pid}) do
    query(access_token, object_id, options, @home_query)
  end


  @facebook_secret "96ba097e3aa68195e1909d0d199b1818"
  def query(access_token, object_id, %{"requires_auth" => false}, [_object_name, fields]) do
    params = %Facebook.Params{access_token: access_token, fields: fields}

    params
    |> Facebook.get_connections(object_id, "posts")
  end
  def query(access_token, object_id, _options, [object_name, fields]) do
    params = %Facebook.Params{access_token: access_token, fields: fields}

    params
    |> Facebook.auth(@facebook_secret)
    |> Facebook.get_connections(object_id, object_name)
  end

  defp ok(object), do: {:ok, object}

  def finish({:ok, collection}, facebook_id) do
    commands = [
      ["set", "ag:fb:#{facebook_id}:fs", Timex.Date.now |> Timex.format("{ISO:Extended}")],
    ]

    last_item = _last_item(collection)
    commands = if last_item do
      commands ++ [["set", "ag:fb:#{facebook_id}", last_item.id]]
    else
      commands
    end

    Redis.query_pipe(commands)

    {:ok, collection}
  end
  def finish({:error, _error} = s, facebook_id) do
    Redis.query_pipe([
      ["set", "ag:fb:#{facebook_id}:fs", Timex.Date.now |> Timex.format("{ISO:Extended}")],
    ])
    s
  end


  @doc"""
  Getting last item from collection of facebook posts to store offset in redis.
  """
  def _last_item(collection) when is_list(collection) do
    collection
    |> Enum.sort_by(fn(val) -> val["created_time"] end)
    |> List.last
    |> _last_item
  end
  def _last_item(nil), do: nil
  def _last_item(item), do: %{id: item["id"], created_time: item["created_time"] }
end
