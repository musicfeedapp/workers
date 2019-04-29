defmodule Db.TimelinePublisher do
  use Ecto.Schema
  use Timex.Ecto.Timestamps

  schema "timeline_publishers" do
    field :user_identifier
    field :timeline_id, :integer

    timestamps([inserted_at: :created_at])
  end
end
