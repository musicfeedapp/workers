defmodule Requesters.Youtube do
  require Poison

  alias Requesters.Http

  def find(developer_id, id), do: _find(developer_id, "/youtube/v3/videos", %{id: id}) |> _snippet

  def categories(developer_id, id), do: _find(developer_id, "/youtube/v3/videoCategories", %{id: id}) |> _snippet

  def search(developer_id, term), do: _find(developer_id, "/youtube/v3/search", %{q: term, maxResults: 1, order: "viewCount"})

  defp _find(developer_id, path, params, part \\ "snippet")
  defp _find(nil, _path, _params, _part), do: {:error, "developer_key required"}
  defp _find(developer_id, path, params, part) do
    params = params |> Map.put(:key, developer_id) |> Map.put(:part, part)
    url = _make_url(path, params)

    {:ok, value} = Http.get(url)

    items = value |> Map.fetch!("items")

    if Enum.count(items) == 0 do
      {:error, "no values in youtube items"}
    else
      {:ok, items |> hd |> Enum.into(%{})}
    end
  end

  defp _make_url(path, params \\ %{}) do
    params = Map.to_list(params)
    :hackney_url.make_url("https://www.googleapis.com", path, params)
  end

  defp _snippet({:error, _error} = s), do: s
  defp _snippet({:ok, %{"snippet" => snippet}}), do: {:ok, snippet}
  defp _snippet(_nothing), do: {:ok, "issue on getting snippet"}
end

defmodule Requesters.Youtube.Link do
  @patterns [
    ~r/v%3D(.*?)%26/,
    ~r/\/v\/(.+)[&#].{0,}$/,
    ~r/v=(.+)[&#].{0,}$/,
    ~r/\/v\/(.+)$/,
    ~r/v=(.+)$/,
    ~r/youtu\.be\/(.+)[&#].{0,}$/,
    ~r/youtu\.be\/(.+)$/,
  ]

  require Requesters.Link
  alias Requesters.Link

  def id(link), do: Link.id(link, @patterns)
  def link(id), do: "http://www.youtube.com/v/#{id}"
  def html_link(id), do: "https://www.youtube.com/watch?v=#{id}"
  def picture(youtube_id), do: "https://i.ytimg.com/vi/#{youtube_id}/hqdefault.jpg"
end
