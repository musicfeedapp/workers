defmodule Requesters.YoutubeHtml do
  require Floki

  alias Requesters.Http
  alias Requesters.Youtube.Link

  def find(url) do
    url |> _request |> metadata
  end

  def metadata({:error, _error} = s), do: s
  def metadata({:ok, html}) do
    id = html |> link |> Link.id
    url = Link.link(id)
    picture = Link.picture(id)
    category = category(html)
    name = name(html)
    view_count = view_count(html)

    {:ok, %{
      name: name,
      category: category,
      link: url,
      id: id,
      picture: picture,
      view_count: view_count,
    }}
  end

  def name(html), do: _name(Floki.find(html, "meta[property=\"og:title\"]"))
  def _name([{"meta", [{"property", "og:title"}, {"content", n}], _}]), do: String.trim(n)
  def _name([]), do: ""

  def category(html) do
    _category(Floki.find(html, "meta[itemprop=\"genre\"]"))
  end
  def _category([{"meta", [{"itemprop", "genre"}, {"content", c}], _}]) do
    c = c |> String.trim |> String.downcase
    if c == "music" or c == "entertainment" do
      c
    else
      _category([])
    end
  end
  def _category([]), do: ""

  def link(html) do
    _link(Floki.find(html, "head link[rel=\"shortlink\""))
  end
  def _link([{"link", [_, {"href", n}], _} | _names]), do: String.trim(n)
  def _link([]), do: ""

  def view_count(html) do
    _view_count(Floki.find(html, ".watch-view-count"))
  end
  def _view_count([{"div", _, [c | _c]} | _]) do
    c
    |> String.trim
    |> String.downcase
    |> String.replace("views", "")
    |> String.replace(",", "")
    |> String.trim
  end
  def _view_count([]), do: 0

  defp _request(url), do: Http.get_raw(url)
end
