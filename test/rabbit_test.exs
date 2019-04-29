defmodule Aggregator.RabbitTest do
  use ExUnit.Case

  alias Requesters.Queue.RabbitConfig, as: RabbitConfig
  alias RedisPoolex, as: Redis
  alias Requesters.Repo
  alias Db.Timeline

  Redis.query(["FLUSHDB"])
  {:ok, conn} = AMQP.Connection.open(RabbitConfig.host)
  {:ok, chan} = AMQP.Channel.open(conn)

  AMQP.Basic.publish chan, "pages.aggregator", "", "{\"access_token\":\"1050849524966077|05a4c25abcedcf87b32e1bbc8e344246\",\"object_id\":\"193270620719880\",\"who\":\"193270620719880\",\"options\":{\"recent\":true}}"

  setup do
    Redis.query(["FLUSHDB"])
    Repo.delete_all(Timeline)
    :ok
  end

  defmodule Helper do
    alias Requesters.Repo

    def count(klass) do
      Repo.aggregate(klass, :count, :id)
    end
  end


  @tag timeout: 51000
  test "workers for rabbit and connections" do
    assert Helper.count(Timeline) == 0

    {:ok, conn} = AMQP.Connection.open(RabbitConfig.host)
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Basic.publish chan, "pages.aggregator", "", "{\"access_token\":\"1050849524966077|05a4c25abcedcf87b32e1bbc8e344246\",\"object_id\":\"193270620719880\",\"who\":\"193270620719880\",\"options\":{\"recent\":true}}"

    :timer.sleep 25000

    assert Helper.count(Timeline) > 0
  end

  @tag timeout: 51000
  test "workers for dead requests" do
    assert Helper.count(Timeline) == 0

    {:ok, conn} = AMQP.Connection.open(RabbitConfig.host)
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Basic.publish chan, "pages.aggregator", "", "deadXbeef"
    :timer.sleep 30000

    assert Helper.count(Timeline) == 0
  end

  @tag timeout: 51000
  test "rabbit dead connections" do
    assert Helper.count(Timeline) == 0

    {:ok, conn} = AMQP.Connection.open(RabbitConfig.host)
    {:ok, chan} = AMQP.Channel.open(conn)

    AMQP.Basic.publish chan,
      "pages.aggregator", "", "{\"access_token\":\"1050849524966077|05a4c25abcedcf87b32e1bbc8e344246\",\"object_id\":\"193270620719880\",\"who\":\"193270620719880\",\"options\":{\"recent\":true}}"

    :timer.sleep 10000

    raise "TEST"

    # Supervisor.which_children(Requesters.Workers.RabbitSupervisor)
    :timer.sleep 1000

    assert Helper.count(Timeline) > 0
  end
end
