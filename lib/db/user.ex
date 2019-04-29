defmodule Db.User do
  use Ecto.Schema

  schema "users" do
    field :facebook_id
  end
end
