defmodule Requesters.SoundcloudTest do
  use ExUnit.Case
  doctest Requesters.Soundcloud

  alias Requesters.Soundcloud

  test "get music metadata 1" do
    {:ok, attributes} = Soundcloud.find("https://soundcloud.com/david-gohlki/leftalone")
    assert attributes.name == "- Left Alone -"
    assert attributes.artist == "Gohlki"
    assert attributes.picture == "https://i1.sndcdn.com/artworks-000131636170-xuhuf5-t500x500.jpg"
  end

  test "get music metadata 2" do
    {:ok, attributes} = Soundcloud.find("https://soundcloud.com/tru-thoughts/oriental-suite-sub-modu-remix")
    assert attributes.name == "Oriental Suite (sUb ModU Remix)"
    assert attributes.picture == "https://i1.sndcdn.com/artworks-000172789199-smdbtl-t500x500.jpg"
    assert attributes.artist == "Tru Thoughts"
  end
end
