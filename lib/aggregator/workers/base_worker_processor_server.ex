defmodule Aggregator.Workers.BaseWorkerProcessorServer do
  alias Requesters.Youtube.Link, as: YoutubeLink
  alias Requesters.Facebook
  alias Requesters.Youtube
  alias Requesters.YoutubeHtml
  alias Requesters.Itunes
  alias Requesters.Spotify
  alias Requesters.Shazam
  alias Requesters.Soundcloud
  alias Requesters.Mixcloud
  alias Models.Timeline
  alias Aggregator.Workers.StorageWorker.StorageSupervisor, as: StorageWorker

  require Logger

  def process({attributes, access_token, options, pid}) do
    try do
      case process(attributes, access_token, options) do
        {:ok, timeline} -> timeline
        {:error, error} ->
          Logger.debug "[BaseWorkerProcessorServer] error: #{inspect(error)}, link: #{inspect(attributes["link"])}"
      end
    rescue
      exception ->
        Logger.debug "[BaseWorkerProcessorServer] received error: #{inspect(Exception.message(exception))}, link: #{inspect(attributes["link"])}"
    end

    GenServer.cast(pid, :dec)
  end

  def process(attributes, access_token, options) do
    attributes
    |> ok
    |> fetch_story_tags(access_token, options)
    |> youtube
    |> spotify
    |> shazam
    |> soundcloud
    |> mixcloud
    |> save!(attributes)
    |> logger_process(attributes)
  end
  defp logger_process({:error, error} = s, attributes) do
    Logger.debug("[process] #{inspect(attributes["id"])} for #{inspect(error)}")
    s
  end
  defp logger_process(s, _attributes), do: s


  @doc """
  Missing link for attributes means we should get more attributes from facebook api
  and merge it with the current version. Then it could be possible to get stream via
  story_bags.

  should be enough to have link and story_tags there.

  We should get more attributes from Facebook API in case of missing details.
  story_tags with type: nil or "" should have required music attributes on the next requests to Facebook API.

  1. get_object by id
  2. fetch story_tags
  3. find tag with type: nil or ""
  4. get_object by id
  5. fetch music attributes
  """
  def fetch_story_tags({:ok, attributes}, _access_token, %{"requires_auth" => false}), do: {:ok, attributes}
  def fetch_story_tags({:ok, %{"link" => nil}} = state, access_token, _options), do: _fetch_story_tags(state, access_token)
  def fetch_story_tags({:ok, %{"link" => ""}} = state, access_token, _options), do: _fetch_story_tags(state, access_token)
  def fetch_story_tags({:ok, _attributes} = state, _access_token, _options), do: state

  @facebook_secret "96ba097e3aa68195e1909d0d199b1818"
  defp _fetch_story_tags({:ok, %{"id" => id} = processing_attributes}, access_token) do
    params = %Facebook.Params{access_token: access_token, fields: "id,link,story_tags"}

    case params |> Facebook.auth(@facebook_secret) |> Facebook.get_object(id) do
      {:ok, %{"link" => nil, "story_tags" => tags}} -> story_tags(tags, processing_attributes, access_token)
      {:ok, %{"link" => "", "story_tags" => tags}} -> story_tags(tags, processing_attributes, access_token)
      {:ok, %{"link" => link}} -> {:ok, Map.merge(processing_attributes, %{"link" => link})}
      {:ok, %{"story_tags" => tags}} -> story_tags(tags, processing_attributes, access_token)
      _ -> {:error, "no story tags"}
    end
  end
  defp story_tags(tags, processing_attributes, access_token) do
    case tags
    |> ok
    |> _extract_story_tags(access_token) do
      {:ok, attributes} -> {:ok, Map.merge(attributes, processing_attributes)}
      {:error, _attributes} = state -> state
    end
  end
  defp _extract_story_tags({:ok, [%{"id" => id, "type" => ""} | _tail]}, access_token), do: _extract_story_tags_build(id, access_token)
  defp _extract_story_tags({:ok, [%{"id" => id, "type" => nil} | _tail]}, access_token), do: _extract_story_tags_build(id, access_token)
  defp _extract_story_tags({:ok, []}, _access_token), do: {:error, "no story tags there for facebook object"}
  defp _extract_story_tags({:ok, [%{"id" => _id, "type" => _type} | tail]}, access_token), do: _extract_story_tags({:ok, tail}, access_token)
  defp _extract_story_tags_build(id, access_token) do
    params = %Facebook.Params{access_token: access_token, fields: "id,link,story_tags"}
    {:ok, response} = Facebook.get_object(id, params)
    name = case response do
             %{"title" => title} -> title
             _ -> nil
           end
    description = case response do
                    %{"description" => description} -> description
                    _ -> nil
                  end
    link = case response do
             %{"url" => url} -> url
             _ -> nil
           end
    stream = case response do
               %{"audio" => [%{"url" => url} | _tail]} -> url
               _ -> nil
             end
    artist = case response do
               %{"data" => %{"musician" => [%{"name" => name} | _tail]}} -> name
               _ -> nil
             end
    {:ok, %{link: link, name: name, description: description, stream: stream, artist: artist}}
  end


  @doc """
  Processing youtube attributes and getting api details from google api.
  Youtube attributes should have category `music` only.
  """
  def youtube({:done, _timeline} = state), do: state
  def youtube({:ok, attributes}), do: _youtube(attributes)
  def youtube({:error, _error} = state), do: state

  defp _youtube(%{"application" => %{ "link" => link }} = attributes), do: _do_youtube(link, attributes)
  defp _youtube(%{"link" => link} = attributes), do: _do_youtube(link, attributes)

  defp _do_youtube(link, attributes) do
    if !String.contains?(link, "youtube.com") && !String.contains?(link, "youtu.be")do
      {:ok, attributes}
    else
      case attributes |> _build_timeline("youtube") do
        {:ok, timeline} ->
          {:done, timeline}
        {:error, _error} = s ->
          s
      end
    end
  end


  def mixcloud({:done, _timeline} = state), do: state
  def mixcloud({:ok, attributes}), do: _mixcloud(attributes)
  def mixcloud({:error, _error} = state), do: state

  defp _mixcloud(%{"application" => %{ "link" => link }} = attributes), do: _do_mixcloud(link, attributes)
  defp _mixcloud(%{"link" => link} = attributes), do: _do_mixcloud(link, attributes)

  defp _do_mixcloud(link, attributes) do
    if !String.contains?(link, "mixcloud.com") do
      {:ok, attributes}
    else
      case attributes |> _build_timeline("mixcloud") do
        {:ok, timeline} ->
          {:done, timeline}
        {:error, _error} = s ->
          s
      end
    end
  end


  def spotify({:done, _timeline} = state), do: state
  def spotify({:ok, attributes}), do: _spotify(attributes)
  def spotify({:error, _error} = state), do: state

  defp _spotify(%{"link" => link} = attributes), do: _do_spotify(link, attributes)
  defp _spotify(%{"application" => %{ "link" => link }} = attributes), do: _do_spotify(link, attributes)

  defp _do_spotify(link, attributes) do
    unless link |> String.contains?("spotify.com") do
      {:ok, attributes}
    else
      case attributes |> _build_timeline("spotify") do
        {:ok, timeline} ->
          {:done, timeline}
        {:error, _error} = s ->
          s
      end
    end
  end


  def shazam({:done, _timeline} = state), do: state
  def shazam({:ok, attributes}), do: _shazam(attributes)
  def shazam({:error, _error} = state), do: state

  defp _shazam(%{"link" => link} = attributes), do: _do_shazam(link, attributes)
  defp _shazam(%{"application" => %{ "link" => link }} = attributes), do: _do_shazam(link, attributes)

  defp _do_shazam(link, attributes) do
    unless link |> String.contains?("shazam.com") do
      {:ok, attributes}
    else
      case attributes |> _build_timeline("shazam") do
        {:ok, timeline} ->
          {:done, timeline}
        {:error, _error} = s ->
          s
      end
    end
  end


  def soundcloud({:done, _timeline} = state), do: state
  def soundcloud({:ok, attributes}), do: _soundcloud(attributes)
  def soundcloud({:error, _error} = state), do: state

  defp _soundcloud(%{"link" => link} = attributes), do: _do_soundcloud(link, attributes)
  defp _soundcloud(%{"application" => %{ "link" => link }} = attributes), do: _do_soundcloud(link, attributes)

  defp _do_soundcloud(link, attributes) do
    unless link |> String.contains?("soundcloud.com") do
      {:ok, attributes}
    else
      case attributes |> _build_timeline("soundcloud") do
        {:ok, timeline} ->
          {:done, timeline}
        {:error, _error} = s ->
          s
      end
    end
  end


  def save!({:done, timeline}, _attributes), do: _save(timeline)
  def save!({:ok, _attributes}, attributes), do: {:error, "can't process attributes and recognize timeline object, #{attributes["link"]}"}
  def save!({:error, _error} = state, _attributes), do: state
  defp _save(timeline) do
    StorageWorker.perform(timeline)
    {:ok, timeline}
  end


  defp _build_timeline(attributes, feed_type) do
    [author_id, author_name, author_picture] = author(attributes)

    [artist, name] = attributes["name"]
      |> String.split("-")
      |> Enum.map(&String.trim/1)
      |> titlelizer


    timeline = %Timeline{
      identifier: attributes["id"],
      feed_type: feed_type,
      import_source: "feed",
      link: attributes["link"],
      name: name || attributes["name"],
      message: attributes["message"],
      likes_count: likes_count(attributes),
      to: to(attributes),
      author: author_name,
      author_picture: author_picture,
      user_identifier: author_id,
      description: attributes["description"],
      published_at: attributes["created_time"],
      artist: artist,
    }

    timeline
    |> ok
    |> assign_api_attributes
    |> validate
    |> assign_itunes_attributes
  end

  defp ok(object), do: {:ok, object}

  @doc """
  Validate categories for timeline object, in case of music it should be passed
  otherwise error produced because of unsupported type.

  ## Examples

      iex> Aggregator.Workers.BaseWorkerProcessorServer.validate({:ok, %Models.Timeline{category: "music"}})
      {:ok, %Models.Timeline{category: "music"}}

      iex> Aggregator.Workers.BaseWorkerProcessorServer.validate({:ok, %Models.Timeline{category: "not music"}})
      {:error, "requires music category"}

  """
  def validate({:ok, timeline}) do
    timeline
    |> ok
    |> _validate_category
  end
  def validate({:error, _error} = s), do: s
  defp _validate_category({:ok, %Timeline{category: "music"}} = state), do: state
  defp _validate_category({:ok, _timeline}), do: {:error, "requires music category"}


  @youtube_api_key "AIzaSyAhXJcYxtBq7cJqh1oKNb1wIefoocMwcTQ"
  def assign_api_attributes({:ok, %Timeline{feed_type: "youtube"} = timeline}) do
    id = YoutubeLink.id(timeline.link)
    link = YoutubeLink.link(id)
    html_link = YoutubeLink.html_link(id)

    {:ok, youtube_attributes} = YoutubeHtml.find(html_link)
    category = youtube_attributes[:category]

    # We have white list for receing updates from facebook(Majesticasual).
    category = if String.contains?(category, "entertainment") and Enum.member?(["221646591235273"], timeline.user_identifier), do: "music", else: category

    timeline = %Timeline{timeline |
                         category: category,
                         youtube_id: id,
                         youtube_link: link,
                         picture: youtube_attributes[:picture],
                         view_count: youtube_attributes[:view_count],
                         source_link: link,
                         link: link}
    {:ok, timeline}
  end


  def assign_api_attributes({:ok, %Timeline{feed_type: "mixcloud"} = timeline}) do
    {:ok, attributes} = Mixcloud.find(timeline.link)

    timeline = %Timeline{timeline |
                         category:  "music",
                         picture:   attributes[:picture],
                         artist:    attributes[:artist],
                         stream:    attributes[:stream]}

    {:ok, timeline}
  end


  def assign_api_attributes({:ok, %Timeline{feed_type: "spotify"} = timeline}) do
    %{album: album, artist: artist, stream: stream, link: link} = Spotify.find(timeline.link)

    case Youtube.search(@youtube_api_key, "#{artist} - #{timeline.name}") do
      {:ok, %{"id" => %{"videoId" => youtube_id}}} ->
        timeline = %Timeline{timeline |
          category: "music",
          album: album,
          artist: artist,
          link: link,
          stream: stream,
          youtube_id: youtube_id,
          youtube_link: YoutubeLink.link(youtube_id),
        }
        {:ok, timeline}
      {:error, _error} -> {:ok, timeline}
    end
  end


  def assign_api_attributes({:ok, %Timeline{feed_type: "shazam"} = timeline}) do
    youtube_response = if timeline.artist do
      Youtube.search(@youtube_api_key, "#{timeline.artist} - #{timeline.name}")
    else
      Youtube.search(@youtube_api_key, timeline.name)
    end

    case youtube_response do
      {:ok, %{"id" => %{"videoId" => youtube_id}}} ->
         case Shazam.find(timeline.link) do
           {:ok, metadata} ->
             timeline = %Timeline{timeline |
               category: "music",
               link: timeline.link,
               youtube_id: youtube_id,
               youtube_link: YoutubeLink.link(youtube_id),
               picture: metadata.picture,
               name: metadata.name,
               artist: metadata.artist,
             }
             {:ok, timeline}
           {:error, _error} = s -> s
         end
      {:error, _error} = s -> s
    end
  end


  def assign_api_attributes({:ok, %Timeline{feed_type: "soundcloud"} = timeline}) do
     case Soundcloud.find(timeline.link) do
       {:ok, metadata} ->
         timeline = %Timeline{timeline | category: "music", picture: metadata.picture}

         timeline = unless timeline.artist do
           %Timeline{timeline | artist: metadata.artist}
         else
           timeline
         end

         {:ok, timeline}
       {:error, _} = s -> s
     end
  end
  def assign_api_attributes({:error, _error} = state), do: state


  @doc """
  Search in itunes by artist and track names and assign to timeline.
  """
  def assign_itunes_attributes({:ok, timeline}) do
    itunes_link = case Itunes.search(timeline.artist, timeline.name) do
                    {:ok, link} -> link
                    _ -> nil
                  end
    timeline = %Timeline{timeline | itunes_link: itunes_link }
    {:ok, timeline}
  end
  def assign_itunes_attributes({:error, _error} = state), do: state


  @doc ~S"""
  Parse the given `array` and extract artist and album name.

  ## Examples
  #
      iex>  Aggregator.Workers.BaseWorkerProcessorServer.titlelizer(["Eminem", "Stan"])
      ["Eminem", "Stan"]

      iex> Aggregator.Workers.BaseWorkerProcessorServer.titlelizer(["Stan"])
      [nil, nil]

      iex> Aggregator.Workers.BaseWorkerProcessorServer.titlelizer(["Eminem", "Stan", "Test"])
      ["Eminem", "Stan - Test"]

  """
  def titlelizer([_a, _b] = value), do: value
  def titlelizer(value) when length(value) > 2, do: [value |> hd, value |> tl |> Enum.join(" - ")]
  def titlelizer(_value), do: [nil, nil]


  @doc """
  ## Examples
  #
      iex> Aggregator.Workers.BaseWorkerProcessorServer.likes_count(%{"likes" => %{ "summary" => %{ "total_count" => 10 }}})
      10
      iex> Aggregator.Workers.BaseWorkerProcessorServer.likes_count(%{"likes" => %{ "summary" => %{  }}})
      0
      iex> Aggregator.Workers.BaseWorkerProcessorServer.likes_count(%{})
      0

  """
  def likes_count(attributes), do: _likes_count(attributes)
  defp _likes_count(%{ "likes" => %{ "summary" => %{ "total_count" => count }}}), do: count
  defp _likes_count(_attributes), do: 0

  @doc """
  ## Examples

      iex> Aggregator.Workers.BaseWorkerProcessorServer.to(%{"to" => %{ "data" => [%{ "id" => 1 }, %{ "id" => 2}]}})
      [1, 2]
      iex> Aggregator.Workers.BaseWorkerProcessorServer.to(%{"to" => %{ "data" => [%{ "id" => 1 }]}})
      [1]
      iex> Aggregator.Workers.BaseWorkerProcessorServer.to(%{})
      []

  """
  def to(attributes), do: _to(attributes)
  defp _to(%{"to" => %{ "data" => users}}), do: users |> Enum.map(fn(user) -> user["id"] end)
  defp _to(_attributes), do: []


  @doc """
  ## Examples

      iex> Aggregator.Workers.BaseWorkerProcessorServer.author(%{"from" => %{ "id" => 1, "name" => "Alexandr Korsak" }})
      [1, "Alexandr Korsak", "http://graph.facebook.com/1/picture?type=normal"]
      iex> Aggregator.Workers.BaseWorkerProcessorServer.author(%{})
      [nil, nil, nil]

  """
  def author(attributes), do: _author(attributes)
  defp _author(%{"from" => %{ "id" => id, "name" => name }}), do: [id, name, "http://graph.facebook.com/#{id}/picture?type=normal"]
  defp _author(_attributes), do: [nil, nil, nil]
end
