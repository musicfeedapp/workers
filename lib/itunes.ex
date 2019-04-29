defmodule Requesters.Itunes do
  require Logger
  require Poison

  alias Requesters.Http

  @moduledoc """
  Search track and artist in itunes and provide the full link to track or
  album there.
  """
  def search(artist, name) do
    case _search([artist, name]) do
      {:ok, _url} = state -> state

      _ -> case _search([artist, ""]) do
             {:ok, _url} = state -> state

             _ -> case _search([name, ""]) do
                    {:ok, _url} = state -> state

                    _ -> _search([name, ""])
                  end
           end
    end
  end

  defp _search(words) do
    term = words |> Enum.join(" ") |> String.trim

    case _request(%{term: term}) do
      {:ok, %{"results" => [results]}} ->
        case results do
          %{"trackViewUrl" => url} -> {:ok, url}
          _ -> {:error, "no defined url"}
        end
      _ -> {:error, "no defined url"}
    end
  end

  def _request(params) do
    params = params
    |> Map.put(:limit, 1)
    |> Map.put(:entry, "song")
    |> Map.put(:country, "us")
    _make_url("/search", params) |> Http.get
  end

  defp _make_url(path, params \\ %{}) do
    params = Map.to_list(params)
    :hackney_url.make_url("https://itunes.apple.com", path, params)
  end
end
