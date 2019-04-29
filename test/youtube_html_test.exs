defmodule Requesters.YoutubeHtmlTest do
  use ExUnit.Case

  test "get video metadata" do
    {:ok, attributes} = Requesters.YoutubeHtml.find("https://www.youtube.com/watch?v=_RtGuUAQOC4")
    assert attributes.name == "'Slow Down' Beautiful Chillstep Mix #6"
    assert attributes.category == "music"
    assert attributes.id == "_RtGuUAQOC4"
    assert attributes.link == "http://www.youtube.com/v/_RtGuUAQOC4"
    assert attributes.view_count == "2442350"
  end
end
