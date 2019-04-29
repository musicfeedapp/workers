defmodule FacebookTest do
  use ExUnit.Case
  doctest Requesters.Facebook

  require Logger

  alias Requesters.Facebook

  @url "https://graph.facebook.com/majesticcasual/posts?fields=id,name,picture,description,link,from,created_time,application,comments.limit(1).summary(true),to,likes.limit(1).summary(true)&access_token=199502190383212|9ae024603797bbcd31d938feba4cd033"
  test "get response with json and add one more item to sidekiq" do
    assert Facebook.id(@url) == "majesticcasual"
  end

  @access_token "EAAHHZBahuow0BAJ4caTvNH12Yi1qGWrSrgg3HLtpQ35uZBBcBEcXRiKtFTpRgJpWRu2rGlxhilnl8TR7iBPjGykhSy6V6R6nSJfWY3FXywiWZANoqZA6Y4g0mcDtxZASh0nVkme2QQF3aUpiEWbeZCqbE8TcNWLjLVg8MkhwWLDgZDZD"
  @object_id "1264937113"
  @facebook_secret "96ba097e3aa68195e1909d0d199b1818"

  test "get_object for facebook" do
    params = %Facebook.Params{access_token: @access_token, fields: "id,name"}
    {:ok, %{"id" => id}} = params |> Facebook.auth(@facebook_secret) |> Facebook.get_object(@object_id)
    assert id == "1264937113"
  end

  test "get_connections for facebook" do
    params = %Facebook.Params{access_token: @access_token, fields: "id,name"}
    {:ok, %{"data" => collection}} = params |> Facebook.auth(@facebook_secret) |> Facebook.get_connections(@object_id, :feed)
    assert Enum.count(collection) == 25
  end

  test "get_connections using pagination" do
    params = %Facebook.Params{access_token: @access_token, fields: "id,name"}
    {:ok, %{"data" => [c1 | c], "paging" => _paging}} = response1 = params |> Facebook.auth(@facebook_secret) |> Facebook.get_connections(@object_id, :feed)
    {:ok, %{"data" => [c2 | c], "paging" => _paging}} = response2 = response1 |> Facebook.next_page
    {:ok, %{"data" => [c3 | c], "paging" => _paging}} = response2 |> Facebook.prev_page

    assert c1 != c2
    # TODO: issue from facebook api on getting next, prev pages and reading data
    # assert c1 == c3
  end
end
