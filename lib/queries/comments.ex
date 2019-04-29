defmodule Queries.Comments do
  import Ecto.Query

  alias Db.Comment
  alias Requesters.Repo

  require Repo
  require Timex
  require Logger

  def ok(attributes), do: {:ok, attributes}

  def create_by({:error, _err} = s), do: s
  def create_by(attributes), do: attributes |> ok |> _create_by

  defp _create_by({:ok, %{user: user, timeline: timeline, t: t, index: index}}) do
    response = {:ok, nil} |> _create_comment(%{
      user_id: user.id,
      eventable_id: "published",
      eventable_type: "Timeline",
      commentable_type: "Timeline",
      commentable_id: timeline.id,
      created_at: timeline.published_at,
    })

    response = response |> _create_comment(%{
      user_id: user.id,
      eventable_id: "default",
      eventable_type: "Playlist",
      commentable_type: "Timeline",
      commentable_id: timeline.id,
      created_at: Timex.DateTime.now,
    })

    response = response |> _create_message(user, timeline, t, index)

    response
  end
  defp _create_by({:error, _error} = s), do: s

  defp _create_comment({:ok, _val}, attributes) do
    query =
      from t in Comment,
      where:
        t.user_id == ^attributes.user_id
        and t.eventable_id == ^attributes.eventable_id
        and t.eventable_type == ^attributes.eventable_type
        and t.commentable_type == ^attributes.commentable_type
        and t.commentable_id == ^attributes.commentable_id,
      limit: 1,
      select: t

    case Repo.one(query) do
      nil ->
        response = struct(Comment, attributes) |> Repo.insert

        case response do
          {:ok, _val} = s -> s
          {:error, changeset} = s ->
            Logger.debug("Error on create comment: #{inspect(changeset)}")
            s
        end
      record -> {:ok, record}
    end
  end
  defp _create_comment({:error, _error} = s, _attributes), do: s

  defp _create_message(response, _user, _timeline, %Models.Timeline{message: ""}, _index), do: response
  defp _create_message(response, _user, _timeline, %Models.Timeline{message: nil}, _index), do: response
  defp _create_message(response, user, timeline, t, 0) do
    response |> _create_comment(%{
          user_id: user.id,
          comment: t.message,
          eventable_id: nil,
          eventable_type: "Comment",
          commentable_type: "Timeline",
          commentable_id: timeline.id,
          created_at: Timex.DateTime.now})
  end
  defp _create_message(response, _user, _timeline, _t, _index), do: response
end
