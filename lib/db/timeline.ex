defmodule Db.Timeline do
  use Ecto.Schema
  use Timex.Ecto.Timestamps

  schema "timelines" do
    field :name
    field :description
    field :link
    field :picture
    field :feed_type
    field :identifier
    field :likes_count, :integer, default: 0
    field :published_at, Timex.Ecto.DateTime
    field :youtube_id
    field :artist
    field :album
    field :source_link
    field :youtube_link
    field :itunes_link
    field :stream
    field :import_source
    field :category
    field :view_count, :integer, default: 0
    field :change_view_count, :integer, default: 0

    timestamps([inserted_at: :created_at])
  end
end
