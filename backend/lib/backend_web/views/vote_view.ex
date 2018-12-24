defmodule BackendWeb.VoteView do
  use BackendWeb, :view

  def render("votes.json", %{votes: votes}) do
    %{ok: true, data: render_many(votes, BackendWeb.VoteView, "vote.json")}
  end

  def render("show.json", %{vote: vote}) do
    %{ok: true, data: render("vote.json", %{vote: vote})}
  end

  def render("vote.json", %{vote: vote}) do
    %{id: vote.id, status: vote.status, ships: vote.ships}
  end
end
