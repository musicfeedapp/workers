defmodule SpotifyTest do
  use ExUnit.Case
  doctest Requesters.Spotify

  alias Requesters.Spotify

  test "get video metadata" do
    attributes = Spotify.find("http://open.spotify.com/track/3CRDbSIZ4r5MsZ0YwxuEkn")
    assert attributes == %{
      album: "Blurryface",
      artist: "Twenty One Pilots",
      link: "http://open.spotify.com/track/3CRDbSIZ4r5MsZ0YwxuEkn",
      stream: "https://p.scdn.co/mp3-preview/0e0951b811f06fea9162eb7e95e4bae4802d97af?cid=null"}
  end

  test "get video metadata for album link" do
    attributes = Spotify.find("https://open.spotify.com/album/4sgC2jgl9J37CajA4tkqYD")
    assert attributes == %{
      album: "Wait for You (Mogul Remix)",
      artist: "Ady Suleiman",
      link: "http://open.spotify.com/track/7n8XQ5C8wtfdknOk932uKV",
      stream: "https://p.scdn.co/mp3-preview/b659d26b9218355f19f9ec5b487aa6aa020a39d3?cid=null"}
  end
end
