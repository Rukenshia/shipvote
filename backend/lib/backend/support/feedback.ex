defmodule Backend.Support.Feedback do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feedback" do
    field :message, :string
    field :channel_id, :id

    timestamps()
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:message])
    |> validate_required([:message])
  end
end
