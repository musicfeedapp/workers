defmodule Queries.Timelines do
  import Ecto.Query

  alias Db.Timeline
  alias Requesters.Repo

  require Logger

  def exists?(%Models.Timeline{identifier: nil, youtube_link: nil, source_link: nil}), do: {:error, nil}
  def exists?(%Models.Timeline{identifier: identifier, youtube_link: nil, source_link: nil}) do
    query =
      from t in Timeline,
      where: t.identifier == ^identifier,
      limit: 1,
      select: t

    _exists_response(Repo.one(query))
  end
  def exists?(%Models.Timeline{identifier: identifier, youtube_link: youtube_link, source_link: nil}) do
    query =
      from t in Timeline,
      where: t.identifier == ^identifier or t.youtube_link == ^youtube_link,
      limit: 1,
      select: t

    _exists_response Repo.one(query)
  end
  def exists?(%Models.Timeline{identifier: identifier, youtube_link: nil, source_link: source_link}) do
    query =
      from t in Timeline,
      where: t.identifier == ^identifier or t.source_link == ^source_link,
      limit: 1,
      select: t

    _exists_response Repo.one(query)
  end
  def exists?(%Models.Timeline{identifier: identifier, youtube_link: youtube_link, source_link: source_link}) do
    query =
      from t in Timeline,
      where: t.identifier == ^identifier or t.source_link == ^source_link or t.youtube_link == ^youtube_link,
      limit: 1,
      select: t

    _exists_response Repo.one(query)
  end

  defp _exists_response(nil), do: {:error, nil}
  defp _exists_response(timeline), do: {:ok, timeline}

  def create_by(t) do
    published_at = t.published_at |> Timex.parse!("{ISO}")

    response = %Db.Timeline{
      name: t.name,
      description: t.description,
      link: t.link,
      picture: t.picture,
      feed_type: t.feed_type,
      identifier: t.identifier,
      likes_count: int(t.likes_count),
      published_at: published_at,
      youtube_id: t.youtube_id,
      artist: t.artist,
      album: t.album,
      source_link: t.source_link,
      youtube_link: t.youtube_link,
      itunes_link: t.itunes_link,
      stream: t.stream,
      import_source: t.import_source,
      category: t.category,
      view_count: int(t.view_count),
    } |> Repo.insert

    case response do
      {:ok, _timeline} = s -> s
      {:error, changeset} -> {:repo_error, changeset}
    end
  end

  def update(exists, t) do
    view_count1 = int(t.view_count)
    view_count2 = int(exists.view_count)

    timeline = Ecto.Changeset.change(exists, change_view_count: view_count2, view_count: view_count1)
    # timeline = Ecto.Changeset.change(exists, change_view_count: view_count1 - view_count2, view_count: view_count1)

    case Repo.update(timeline) do
      {:ok, _timeline} = s -> s
      {:error, changeset} -> {:repo_error, changeset}
    end
  end

  defp int(val) when is_bitstring(val) do
    {v, _} = Integer.parse(val)
    v
  end
  defp int(val) when is_nil(val), do: 0
  defp int(val), do: val
end
