defmodule Requesters.Spotify do
  require Requesters.Http
  require Poison
  require Logger

  alias Requesters.Http
  alias Requesters.Spotify.Link

  @doc """
  Respond with attributes from Spotify API, we will get artist, stream url.
  """
  def find(url) do
    url |> _match_url |> _find
  end

  defp _match_url(url) do
    response = {:error, "no match"}

    response = if Regex.match?(~r/spotify\.com\/track\/(.+)$/, url) do
      {:track, url}
    else
      response
    end

    response = if Regex.match?(~r/spotify\.com\/album\/(.+)$/, url) do
      {:album, url}
    else
      response
    end

    response
  end

  defp _find({:track, url}) do
    id = Link.id(url)
    url = _make_url("/v1/tracks/#{id}")
    url |> _request |> metadata(:track, id)
  end
  defp _find({:album, url}) do
    id = Link.id(url)
    url = _make_url("/v1/albums/#{id}")
    url |> _request |> metadata(:album, id)
  end
  defp _find({:error, error} = s) do
    Logger.debug(inspect(error))
    s
  end

  def metadata({:error, _error} = s, :track, _), do: s
  def metadata({:ok, attributes}, :track, id) do
    album = case attributes do
      %{"album" => %{"name" => name}} -> name
      _ -> nil
    end

    artist = case attributes do
      %{"artists" => [%{"name" => name} | _]} -> name
       _ -> nil
    end

    stream = case attributes do
      %{"preview_url" => url} -> url
      _ -> nil
    end

    link = Link.link(id)

    %{album: album, artist: artist, stream: stream, link: link}
  end

  def metadata({:error, _error} = s, :album, _), do: s
  def metadata({:ok, attributes}, :album, _) do
    album = case attributes do
      %{"name" => name} -> name
      _ -> nil
    end

    artist = case attributes do
      %{"artists" => [%{"name" => name} | _]} -> name
       _ -> nil
    end

    {stream, track_id} = case attributes do
      %{"tracks" => %{"items" => [%{"preview_url" => url, "id" => track_id} | _]}} -> {url, track_id}
      _ -> nil
    end

    link = Link.link(track_id)

    %{album: album, artist: artist, stream: stream, link: link}
  end

  defp _request(url), do: Http.get(url)

  defp _make_url(path, params \\ %{}) do
    params = params
    |> Map.to_list
    :hackney_url.make_url("https://api.spotify.com", path, params)
  end
end

defmodule Requesters.Spotify.Link do
  @patterns [
    ~r/spotify\.com\/track\/(.+)$/,
    ~r/spotify\:track\:(.+)$/,
    ~r/spotify\.com\/album\/(.+)$/,
    ~r/spotify\:album\:(.+)$/,
  ]

  require Requesters.Link
  alias Requesters.Link

  def id(link), do: Link.id(link, @patterns)
  def link(id), do: "http://open.spotify.com/track/#{id}"
end
