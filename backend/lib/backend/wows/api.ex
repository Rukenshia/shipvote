defmodule Backend.Wows.Api do
  require Logger

  @application Application.get_env(:backend, Backend.Wows.Api)[:application]
  @ship_fields "is_premium,images.small,nation,ship_id,tier,type,name,description,is_special,next_ships"

  def get_warships(page, ships) do
    %{status_code: 200} =
      response =
      HTTPoison.get!("https://api.worldofwarships.eu/wows/encyclopedia/ships/", [],
        params: %{application_id: @application, fields: @ship_fields, page_no: page}
      )

    %{"status" => "ok"} = data = Jason.decode!(response.body)

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
    %{status_code: 200} =
      response =
      HTTPoison.get!("https://api.worldofwarships.eu/wows/encyclopedia/ships/", [],
        params: %{application_id: @application, fields: @ship_fields}
      )

    %{"status" => "ok"} = data = Jason.decode!(response.body)

    ships = data["data"]

    if data["meta"]["page"] < data["meta"]["page_total"] do
      get_warships(data["meta"]["page"] + 1, ships)
    else
      ships
    end
  end

  def find_account_id(username, realm) do
    response =
      HTTPoison.get!("#{realm_url(realm)}/wows/account/list/", [],
        params: %{application_id: @application, search: username, type: "exact", limit: 1}
      )

    with %{"status" => "ok"} = data <- Jason.decode!(response.body) do
      if data["data"] |> length == 0 do
        Logger.error("Player Lookup without data: #{inspect(data)}")
        {:error, "Player not found"}
      else
        {:ok, (data["data"] |> Enum.at(0))["account_id"]}
      end
    else
      %{"error" => %{"message" => message}} ->
        Logger.error("Warships API error: #{message}")
        {:error, "Warships API returned an error"}

      e ->
        Logger.error("Warships API unknown error: #{inspect(e)}")
        {:error, "e_unknown"}
    end
  end

  def get_account_ships(account_id, realm) do
    response =
      HTTPoison.get!("#{realm_url(realm)}/wows/ships/stats/", [],
        params: %{
          application_id: @application,
          account_id: account_id,
          fields: "ship_id",
          in_garage: 1
        }
      )

    with %{"status" => "ok"} = data <- Jason.decode!(response.body) do
      if data["meta"]["count"] != 1 do
        {:error, "Player not found"}
      else
        {:ok, data["data"]["#{account_id}"] |> Enum.map(fn e -> e["ship_id"] end)}
      end
    else
      %{"error" => %{"message" => message}} ->
        Logger.error("Warships API error: #{message}")
        {:error, "Warships API returned an error"}

      e ->
        Logger.error("Warships API unknown error: #{inspect(e)}")
        {:error, "e_unknown"}
    end
  end

  defp realm_url("na") do
    "https://api.worldofwarships.com"
  end

  defp realm_url(realm) do
    "https://api.worldofwarships.#{realm}"
  end
end
