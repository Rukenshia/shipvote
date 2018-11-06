defmodule BackendWeb.WarshipView do
  use BackendWeb, :view
  alias BackendWeb.WarshipView

  def render("index.json", %{warships: warships}) do
    %{data: render_many(warships, WarshipView, "warship.json")}
  end

  def render("show.json", %{warship: warship}) do
    %{data: render_one(warship, WarshipView, "warship.json")}
  end

  def render("warship.json", %{warship: warship}) do
    %{
      id: warship.id,
      name: warship.name,
      nation: warship.nation,
      type: warship.type,
      tier: warship.tier,
      premium: warship.premium,
      image: warship.image
    }
  end
end
