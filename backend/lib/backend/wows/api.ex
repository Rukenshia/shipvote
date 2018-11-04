defmodule Backend.Wows.Api do
  require Logger

  @application Application.get_env(:backend, Backend.Wows.Api)[:application]
  @ship_fields "is_premium,images.small,nation,ship_id,tier,type,name"

  def get_warships(page, ships) do
    response =
      HTTPoison.get!("https://api.worldofwarships.eu/wows/encyclopedia/ships/", [],
        params: %{application_id: @application, fields: @ship_fields, page_no: page}
      )

    data = Poison.decode!(response.body)

    new_ships = data["data"]

    ships =
      ships
      |> Map.merge(new_ships)

    if data["meta"]["page"] < data["meta"]["page_total"] do
      get_warships(data["meta"]["page"] + 1, ships)
    else
      ships
    end
  end

  def get_warships() do
    response =
      HTTPoison.get!("https://api.worldofwarships.eu/wows/encyclopedia/ships/", [],
        params: %{application_id: @application, fields: @ship_fields}
      )

    data = Poison.decode!(response.body)

    ships = data["data"]

    if data["meta"]["page"] < data["meta"]["page_total"] do
      get_warships(data["meta"]["page"] + 1, ships)
    else
      ships
    end
  end
end
