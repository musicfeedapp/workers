defmodule Db.Comment do
  use Ecto.Schema
  use Timex.Ecto.Timestamps

  schema "comments" do
    field :commentable_id, :integer
    field :commentable_type
    field :user_id, :integer
    field :role, :string, default: "comments"
    field :eventable_type, :string, default: "Comment"
    field :eventable_id

    timestamps([inserted_at: :created_at])
  end
end
