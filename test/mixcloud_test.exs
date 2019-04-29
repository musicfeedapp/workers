defmodule Requesters.MixcloudTest do
  use ExUnit.Case

  doctest Requesters.Mixcloud
  alias Requesters.Mixcloud

  test "should returns metadata mixcloud" do
    {:ok, attributes} = Mixcloud.find("https://www.mixcloud.com/zoviet_france/a-duck-in-a-tree-2016-07-09-anamnesis/")

    assert attributes.stream == "https://stream1.mixcloud.com/c/originals/a/b/2/4/8c32-707b-43e6-b2ca-8656a3a9635e.mp3"
    assert attributes.picture == "https://thumbnailer.mixcloud.com/unsafe/600x600/extaudio/4/2/a/a/75a2-ed80-41f3-ba7e-75fd74515c9f"
    assert attributes.artist == ":zoviet*france:"
  end

  test "should returns metadata mixcloud from profile page" do
    {:ok, attributes} = Mixcloud.find("https://www.mixcloud.com/above-all/")
    assert attributes.picture == "https://thumbnailer.mixcloud.com/unsafe/256x256/profile/3/d/3/4/36d1-fcfd-4745-9c78-1d42b6f32e7d"
  end
end
