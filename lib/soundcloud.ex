defmodule Requesters.Soundcloud do
  require Requesters.Http
  require Logger
  require Floki

  alias Requesters.Http

  def find(url) do
    url |> _request |> metadata
  end

  def metadata({:error, _error} = s), do: s
  def metadata({:ok, html}) do
    {:ok, %{name: name(html), artist: artist(html), picture: picture(html)}}
  end

  def picture(html) do
    _picture(Floki.attribute(html, "meta[property='og:image']", "content"))
  end
  defp _picture([]), do: ""
  defp _picture([image]), do: image

  def artist(html) do
    _artist Floki.find(html, "header a")
  end
  def _artist([_, {_, [_], [a]}]), do: String.trim(a)
  def _artist(_), do: ""

  def name(html) do
    _name(Floki.attribute(html, "meta[property='og:title']", "content"))
  end
  defp _name([]), do: ""
  defp _name([name]), do: name

  defp _request(url), do: Http.get_raw(url)
end
