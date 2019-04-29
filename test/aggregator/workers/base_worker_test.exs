defmodule Aggregator.Workers.BaseWorkerProcessorServerTest do
  use ExUnit.Case, async: true

  doctest Aggregator.Workers.BaseWorkerProcessorServer

  require Poison
  require Logger

  alias Aggregator.Workers.BaseWorkerProcessorServer
  alias Aggregator.Workers.BaseWorker

  @access_token "EAAHHZBahuow0BAJ4caTvNH12Yi1qGWrSrgg3HLtpQ35uZBBcBEcXRiKtFTpRgJpWRu2rGlxhilnl8TR7iBPjGykhSy6V6R6nSJfWY3FXywiWZANoqZA6Y4g0mcDtxZASh0nVkme2QQF3aUpiEWbeZCqbE8TcNWLjLVg8MkhwWLDgZDZD"
  # @object_id "1264937113"
  @auth_options %{"requires_auth" => true}

  # TODO: requires to have the latest access_token or add VCR
  # test "get posts for user" do
  #   {:ok, %{"data" => collection}} = BaseWorker.collector_for({@access_token, @object_id, :me, %{}, nil})
  #   assert Enum.count(collection) == 25
  # end

  test "run processing for youtube" do
    attributes = fixture("youtube.json")
    {:ok, timeline} = BaseWorkerProcessorServer.process(attributes, @access_token, @auth_options)
    assert timeline.identifier == "1264937113_10208594264555133"
    assert timeline.feed_type == "youtube"
    assert timeline.youtube_id == "2iMT_vj38pI"
    assert timeline.youtube_link == "http://www.youtube.com/v/2iMT_vj38pI"
    assert timeline.category == "music"
    assert timeline.name == "|First 3 Hours Female Vocal Dubstep mix 2015"
    assert timeline.itunes_link == nil
  end

  test "run processing for youtube - example" do
    attributes = fixture("youtube-example.json")
    {:ok, timeline} = BaseWorkerProcessorServer.process(attributes, @access_token, @auth_options)
    assert timeline.identifier == "1264937113_10208100720056829"
    assert timeline.feed_type == "youtube"
    assert timeline.youtube_id == "nky4me4NP70"
    assert timeline.youtube_link == "http://www.youtube.com/v/nky4me4NP70"
    assert timeline.category == "music"
    assert timeline.name == "twenty one pilots: Tear In My Heart [OFFICIAL VIDEO]"
    assert timeline.itunes_link == nil
  end

  test "run processing for spotify" do
    attributes = fixture("spotify.json")
    {:ok, timeline} = BaseWorkerProcessorServer.process(attributes, @access_token, @auth_options)
    assert timeline.identifier == "1264937113_10208010464920507"
    assert timeline.name == "Stressed Out"
    assert timeline.feed_type == "spotify"
    assert timeline.itunes_link != nil
    assert timeline.link == "http://open.spotify.com/track/3CRDbSIZ4r5MsZ0YwxuEkn"
    assert timeline.album == "Blurryface"
    assert timeline.stream == "https://p.scdn.co/mp3-preview/0e0951b811f06fea9162eb7e95e4bae4802d97af"
    assert timeline.artist == "Twenty One Pilots"
    assert timeline.youtube_link != nil
    assert timeline.youtube_id != nil
  end

  # TODO: no story tags, what to do?
  # test "run processing for spotify with missing link 1" do
  #   attributes = fixture("spotify-missing-link.json")
  #   {:ok, timeline} = BaseWorkerProcessorServer.process(attributes, @access_token, @auth_options)
  #   assert timeline.identifier == "1264937113_10208010464920507"
  #   assert timeline.name == "Stressed Out"
  #   assert timeline.feed_type == "spotify"
  #   assert timeline.itunes_link != nil
  #   assert timeline.link == "http://open.spotify.com/track/3CRDbSIZ4r5MsZ0YwxuEkn"
  #   assert timeline.album == "Blurryface"
  #   assert timeline.stream == "https://p.scdn.co/mp3-preview/0e0951b811f06fea9162eb7e95e4bae4802d97af"
  #   assert timeline.artist == "Twenty One Pilots"
  #   assert timeline.youtube_link != nil
  #   assert timeline.youtube_id != nil
  # end

  # TODO: no story tags, what to do?
  # test "run processing for spotify with missing link 2" do
  #   attributes = fixture("spotify-missing-link-2.json")
  #   {:ok, timeline} = BaseWorkerProcessorServer.process(attributes, @access_token, @auth_options)
  #   assert timeline.identifier == "1264937113_10209108051519486"
  #   assert timeline.name == "Сказочная тайга"
  #   assert timeline.feed_type == "spotify"
  #   assert timeline.itunes_link != nil
  #   assert timeline.link == "http://open.spotify.com/track/7nJskgmrv6qflN5WFnnM33"
  #   assert timeline.album == "Опиум"
  #   assert timeline.stream == "https://p.scdn.co/mp3-preview/eb5ed56a8a7f27444d7a237bd9990d6b6eb25d00"
  #   assert timeline.artist == "Агата Кристи"
  #   assert timeline.youtube_link != nil
  #   assert timeline.youtube_id != nil
  # end

  # TODO: fix it, now shazam is js app
  # test "run processing for shazam" do
  #   attributes = fixture("shazam.json")
  #   {:ok, timeline} = BaseWorkerProcessorServer.process(attributes, @access_token, @auth_options)
  #   assert timeline.identifier == "1264937113_10209147806233329"
  #   assert timeline.name == "Pieces"
  #   assert timeline.feed_type == "shazam"
  #   assert timeline.itunes_link != nil
  #   assert timeline.link == "http://www.shazam.com/track/40541964"
  #   assert timeline.album == nil
  #   assert timeline.stream == nil
  #   assert timeline.artist == "Sum 41"
  #   assert timeline.youtube_link == "http://www.youtube.com/v/g8z-qP34-1Y"
  #   assert timeline.youtube_id == "g8z-qP34-1Y"
  # end

  test "run processing for soundcloud" do
    attributes = fixture("soundcloud.json")
    {:ok, timeline} = BaseWorkerProcessorServer.process(attributes, @access_token, @auth_options)
    assert timeline.feed_type == "soundcloud"
    assert timeline.identifier == "1264937113_10209148192722991"
    assert timeline.name == "No Heart"
    assert timeline.artist == "21 Savage"
    assert timeline.link == "https://soundcloud.com/21savage/no-heart"
    assert timeline.itunes_link == "https://itunes.apple.com/us/album/no-heart/id1133782044?i=1133782349&uo=4"
    assert timeline.picture == "https://i1.sndcdn.com/artworks-000171598151-4h3pp6-t500x500.jpg"
    assert timeline.album == nil
    assert timeline.stream == nil
    assert timeline.youtube_link == nil
    assert timeline.youtube_id == nil
  end

  def fixture(filename) do
    File.read!("#{System.cwd()}/test/aggregator/workers/_fixtures/#{filename}") |> Poison.decode!
  end
end
