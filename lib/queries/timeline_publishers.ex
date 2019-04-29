defmodule Queries.TimelinePublishers do
  import Ecto.Query

  alias Db.TimelinePublisher
  alias Queries.Users
  alias Requesters.Repo

  require Logger

  def create(timeline, t), do: _create(timeline, t)

  def _create(timeline, t) do
    t
    |> Users.all
    |> Enum.map(fn(user) ->
      case _find_by(timeline, user) do
        nil -> %Db.TimelinePublisher{user_identifier: user.facebook_id, timeline_id: timeline.id}
        _ -> nil
      end
    end)
    |> Enum.filter(fn(record) -> record != nil end)
    |> _create_records(timeline)
  end

  defp _create_records([], timeline), do: {:ok, timeline}
  defp _create_records(collection, timeline) when is_list(collection) do
    collection
    |> Enum.each(fn(timeline_publisher) -> Repo.insert(timeline_publisher) end)

    {:ok, timeline}
  end

  def _find_by(timeline, user) do
    query =
      from p in TimelinePublisher,
      where: p.timeline_id == ^timeline.id and p.user_identifier == ^user.facebook_id,
      limit: 1,
      select: p

    Repo.one(query)
  end
end
