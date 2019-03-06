defmodule BackendWeb.VoteView do
  use BackendWeb, :view

  def render("votes.json", %{votes: votes}) do
    %{ok: true, data: render_many(votes, BackendWeb.VoteView, "vote.json")}
  end

  def render("show.json", %{vote: vote}) do
    %{ok: true, data: render("vote.json", %{vote: vote})}
  end

  def render("vote.json", %{vote: vote}) do
    %{
      id: vote.id,
      status: vote.status,
      ships: vote.ships,
      votes: %{},
      updated_at: vote.updated_at
    }
    |> render_voted_ships(vote)
  end

  defp render_voted_ships(data, vote) do
    if Ecto.assoc_loaded?(vote.votes) do
      %{
        data
        | votes:
            Enum.map(vote.votes, fn v -> v.ship_id end)
            |> Enum.reduce(%{}, fn x, acc ->
              Map.update(acc, x, 1, &(&1 + 1))
            end)
      }
    else
      data
    end
  end
end
