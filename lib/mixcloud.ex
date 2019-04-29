defmodule Requesters.Mixcloud do
  require Floki

  alias Requesters.Http

  def find(url) do
    url |> _request |> metadata
  end

  def metadata({:error, _error} = s), do: s
  def metadata({:ok, html}) do
    {:ok, %{
        stream: stream(html),
        picture: picture(html),
        artist: artist(html)
      }
    }
  end

  def stream(html) do
    url = _stream(Regex.scan(~r/m\-preview\=\"((.+)\.mp3)\"/, html))

    url = if url != "" do
      url = Regex.replace(~r/audiocdn(\d+)/, url, "stream\\1")
      url = url |> String.replace("/previews/", "/c/originals/")

      unless _verify(url) do
        url = url
              |> String.replace(".mp3", ".m4a")
              |> String.replace("originals/", "m4a/64/")

        url = unless _verify(url) do
          ""
        else
          url
        end
      end
    else
      url
    end

    url
  end
  def _stream([[_, url, _] | _]), do: String.trim(url)
  def _stream([]), do: ""

  def picture(html) do
    pic = _picture(Floki.find(html, ".show-header .sidebar img"))

    pic = if pic == "" do
      _picture(Floki.find(html, ".profile-header img.avatar"))
    else
      pic
    end

    pic
  end
  def _picture([{"img", attributes, _}]) do
    attributes
    |> Enum.find(fn {k, _} -> k == "src" end)
    |> case do
      {"src", src} ->
        src
        |> String.replace("300x300", "600x600")
        |> String.replace("128x128", "256x256")
      _ -> ""
    end
  end
  def _picture([]), do: ""

  def artist(html) do
    _artist(Floki.find(html, ".title-wrapper .title-inner-wrapper div span a"))
  end
  def _artist([{"a", _, [a]}]), do: String.trim(a)
  def _artist([]), do: ""

  defp _request(url), do: Http.get_raw(url)

  defp _verify(:ok), do: true
  defp _verify({:error, _error}), do: false
  defp _verify(url), do: _verify(Http.head(url))
end
