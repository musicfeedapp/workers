defmodule Aggregator.Workers.StorageWorker.ElasticServer do
  use GenServer

  require Logger

  defmodule Indexer do
    import Tirexs.Bulk

    def run(timeline) do
      env = Application.get_env(:requesters, :environment)
      env = if env == "prod" do
        "production"
      else
        env
      end

      payload = bulk([index: "timelines-#{env}", type: "Timeline"]) do
        index [
          [
            id: timeline.id,
            name: timeline.name,
            artist: timeline.artist,
            description: timeline.description,
          ]
        ]
      end

      Tirexs.bump!(payload)._bulk
    end
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_opts) do
    {:ok, nil}
  end

  def index(timeline) do
    GenServer.cast(__MODULE__, {:index, timeline})
  end

  def handle_cast({:index, timeline}, state) do
    Indexer.run(timeline)
    {:noreply, state}
  end
end
