defmodule Aggregator.YoutubeTest do
  use ExUnit.Case
  doctest Requesters.Youtube

  alias Requesters.Youtube

  require Logger

  @developer_key "AIzaSyAhXJcYxtBq7cJqh1oKNb1wIefoocMwcTQ"
  @youtube_id "OpzqO-j9r6s"
  test "get video metadata" do
    {:ok, youtube_attributes} = Youtube.find(@developer_key, @youtube_id)
    assert youtube_attributes["categoryId"] == "10"

    Logger.info "YOUTUBE: inspect(youtube_attributes)"

    {:ok, categories_attributes} = Youtube.categories(@developer_key, youtube_attributes["categoryId"])
    assert categories_attributes["title"] == "Music"
  end

  test "search track by name" do
    {:ok, %{ "id" => %{ "videoId" => youtube_id } }} = Youtube.search(@developer_key, "Eminem - Stan")
    assert youtube_id == "gOMhN-hfMtY"
  end
end

defmodule Aggregator.Youtube.LinkTest do
  use ExUnit.Case

  doctest Requesters.Youtube.Link

  alias Requesters.Youtube.Link

  test "render youtube link" do
    assert Link.link("test") == "http://www.youtube.com/v/test"
  end

  test "parse youtube links" do
    for link <- [
      "http://www.youtube.com/v/yo9ltfmS5n4",
      "http://www.youtube.com/watch?v=yo9ltfmS5n4",
      "https://www.youtube.com/watch?v=yo9ltfmS5n4",
      "https://www.youtube.com/watch?v=yo9ltfmS5n4#test=param1",
      "https://www.youtube.com/watch?v=yo9ltfmS5n4&test=param1",
      "https://www.youtube.com/watch?v=yo9ltfmS5n4&index=2",
      "https://www.youtube.com/v/yo9ltfmS5n4&index=2",
      "http://youtu.be/yo9ltfmS5n4",
      "http://youtu.be/yo9ltfmS5n4&list=PLCuEH5Tl2B8pNiAzALVqHwmQxp8mt-naG",
      "http://www.youtube.com/attribution_link?a=3GW6p2yj67o&u=%2Fwatch%3Fv%3Dyo9ltfmS5n4%26feature%3Dshare",
      "http://www.youtube.com/attribution_link?a=bxcJolSOapM&u=%2Fwatch%3Fv%3Dyo9ltfmS5n4%26feature%3Dshare%26list%3DPLE7tQUdRKcyYOPhZMxw2h84PpO8CIjqsK",
      "https://www.youtube.com/attribution_link?a=KjinOlATF7o&u=%2Fwatch%3Fv%3Dyo9ltfmS5n4%26list%3DRDpXRviuL6vMY%26feature%3Dshare"
    ] do
      assert Link.id(link) == "yo9ltfmS5n4"
    end
  end

  test "parse example 2 youtube links" do
    assert Link.id("https://youtu.be/_RtGuUAQOC4") == "_RtGuUAQOC4"
  end
end
