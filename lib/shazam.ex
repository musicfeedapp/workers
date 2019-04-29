defmodule Requesters.Shazam do
  require Requesters.Http
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
    _picture(Floki.attribute(html, ".art.flex-reset img", "src"))
  end
  defp _picture([image | _images]), do: image
  defp _picture([]), do: ""

  def artist(html) do
    _artist(Floki.find(html, ".details h2 a"))
  end
  defp _artist([{"a", [_href], [a | _c]} | _artists]), do: String.trim(a)
  defp _artist([]), do: ""

  def name(html) do
    _name(Floki.find(html, ".details h1"))
  end
  defp _name([{"h1", [_, _, _], [n | _c]} | _names]), do: String.trim(n)
  defp _name([]), do: ""

  defp _request(url), do: Http.get_raw(url)
end
