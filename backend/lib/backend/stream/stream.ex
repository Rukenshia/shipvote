defmodule Backend.Stream do
  @moduledoc """
  The Wows context.
  """

  import Ecto.Query, only: [from: 2]
  alias Backend.Repo

  alias Backend.Stream.Vote

  def get_open_vote_by_channel(channel) do
    from(v in Vote,
      where: v.channel_id == ^channel and v.status == "open"
    )
    |> Repo.one()
  end
end
