defmodule ItunesTest do
  use ExUnit.Case, async: true
  doctest Requesters.Facebook

  alias Requesters.Itunes

  test "search itunes track there by term" do
    {:ok, url} = Itunes.search("Eminem", "Stan")
    assert url == "https://itunes.apple.com/us/album/stan/362114?i=362077&uo=4"
  end
end
