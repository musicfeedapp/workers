defmodule Queries.Users do
  import Ecto.Query

  alias Db.User
  alias Requesters.Repo

  def all(timeline) do
    identifiers = []

    identifiers = if timeline.user_identifier do
      identifiers ++ [timeline.user_identifier]
    else
      identifiers
    end

    identifiers = if timeline.artist_identifier do
      identifiers ++ [timeline.artist_identifier]
    else
      identifiers
    end

    identifiers = to(identifiers, timeline.to)

    query =
      from u in User,
      where: u.facebook_id in ^identifiers,
      select: u

    Repo.all(query)
  end

  def to(identifiers, v) when is_bitstring(v), do: to(identifiers, [v])
  def to(identifiers, v) when is_nil(v), do: identifiers
  def to(identifiers, v) do
    v
    |> Enum.reduce(identifiers, fn(k, acc) -> acc ++ [k] end)
    |> Enum.uniq
  end
end
