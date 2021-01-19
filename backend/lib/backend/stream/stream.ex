defmodule Backend.Stream do
  require Logger

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

  def get_open_votes() do
    from(v in Vote,
      where: v.status == "open"
    )
    |> Repo.all()
  end

  @doc """
  Returns either a cached version of a vote or retrieves it from the database
  """
  def get_cached_vote(vote_id) do
    ConCache.get_or_store(:vote_cache, "vote_#{vote_id}", fn ->
      case Repo.get(Vote, vote_id) do
        %Vote{} = v -> %ConCache.Item{value: v |> Repo.preload(:votes), ttl: :timer.seconds(5)}
        nil -> %ConCache.Item{value: :not_found, ttl: :timer.seconds(60)}
      end
    end)
  end

  alias Backend.Stream.Channel

  @doc """
  Returns the list of channels.

  ## Examples

      iex> list_channels()
      [%Channel{}, ...]

  """
  def list_channels do
    Repo.all(Channel)
  end

  @doc """
  Gets a single channel.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(123)
      %Channel{}

      iex> get_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(id), do: Repo.get!(Channel, id)
  def get_channel(id), do: Repo.get(Channel, id)

  @doc """
  Creates a channel.

  ## Examples

      iex> create_channel(%{field: value})
      {:ok, %Channel{}}

      iex> create_channel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel(attrs \\ %{}) do
    Appsignal.increment_counter("num_channels")

    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel.

  ## Examples

      iex> update_channel(channel, %{field: new_value})
      {:ok, %Channel{}}

      iex> update_channel(channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Channel.

  ## Examples

      iex> delete_channel(channel)
      {:ok, %Channel{}}

      iex> delete_channel(channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_channel(%Channel{} = channel) do
    Repo.delete(channel)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(channel)
      %Ecto.Changeset{source: %Channel{}}

  """
  def change_channel(%Channel{} = channel) do
    Channel.changeset(channel, %{})
  end

  alias Backend.Stream.ChannelShip

  @doc """
  Returns the list of channel_ships.

  ## Examples

      iex> list_channel_ships()
      [%ChannelShip{}, ...]

  """
  def list_channel_ships(channel_id) do
    from(s in ChannelShip, where: s.channel_id == ^channel_id)
    |> Repo.all()
    |> Repo.preload(:ship)
  end

  @doc """
  Gets a single channel_ship.

  Raises `Ecto.NoResultsError` if the Channel ship does not exist.

  ## Examples

      iex> get_channel_ship!(123)
      %ChannelShip{}

      iex> get_channel_ship!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel_ship!(id), do: Repo.get!(ChannelShip, id)

  @doc """
  Creates a channel_ship.

  ## Examples

      iex> create_channel_ship(%{field: value})
      {:ok, %ChannelShip{}}

      iex> create_channel_ship(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel_ship(attrs \\ %{}) do
    %ChannelShip{}
    |> ChannelShip.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel_ship.

  ## Examples

      iex> update_channel_ship(channel_ship, %{field: new_value})
      {:ok, %ChannelShip{}}

      iex> update_channel_ship(channel_ship, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel_ship(%ChannelShip{} = channel_ship, attrs) do
    channel_ship
    |> ChannelShip.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a channels ships from the WoWS API
  """
  def update_channel_ships(channel) do
    channel =
      channel
      |> Repo.preload(:ships)

    Logger.debug("update_channel_ships.account_id=#{channel.wows_account_id}")

    with {:ok, ships} <-
           Backend.Wows.Api.get_account_ships(channel.wows_account_id, channel.wows_realm) do
      Logger.debug("update_channel_ships.ships_before_filter=#{ships |> length}")

      # only insert ships that exist in our database
      ships =
        from(s in Backend.Wows.Warship, where: s.id in ^ships)
        |> Repo.all()

      ship_ids = Enum.map(ships, fn s -> s.id end)

      Logger.debug("update_channel_ships.ships_after_filter=#{ships |> length}")

      # save the current ships so that we can use them to retain settings
      current_ships =
        from(s in Backend.Stream.ChannelShip, where: s.channel_id == ^channel.id) |> Repo.all()

      current_ship_ids = Enum.map(current_ships, fn s -> s.ship_id end)

      Logger.debug("update_channel_ships.inserting.ships=#{ships |> length}")

      # insert ships that don't exist
      for ship <- Enum.filter(ships, fn s -> not (s.id in current_ship_ids) end) do
        Logger.debug("update_channel_ships.inserting.channel_id=#{channel.id},ship=#{ship.id}")

        %Backend.Stream.ChannelShip{}
        |> Backend.Stream.ChannelShip.changeset(%{
          channel_id: channel.id,
          ship_id: ship.id,
          enabled: true
        })
        |> Repo.insert()
      end

      # remove ships that we don't need
      for ship <- Enum.filter(current_ships, fn s -> not (s.ship_id in ship_ids) end) do
        ship
        |> Repo.delete!()
      end

      {:ok, get_channel!(channel.id) |> Repo.preload(:ships)}
    else
      {:error, e} ->
        {:error, e}
    end
  end

  @doc """
  Deletes a ChannelShip.

  ## Examples

      iex> delete_channel_ship(channel_ship)
      {:ok, %ChannelShip{}}

      iex> delete_channel_ship(channel_ship)
      {:error, %Ecto.Changeset{}}

  """
  def delete_channel_ship(%ChannelShip{} = channel_ship) do
    Repo.delete(channel_ship)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel_ship changes.

  ## Examples

      iex> change_channel_ship(channel_ship)
      %Ecto.Changeset{source: %ChannelShip{}}

  """
  def change_channel_ship(%ChannelShip{} = channel_ship) do
    ChannelShip.changeset(channel_ship, %{})
  end

  @doc """
  Updates the status of an existing Vote.
  """
  def change_vote_status(vote_id, status) do
    with %Vote{} = vote <- Repo.get(Vote, vote_id) do
      case vote
           |> Vote.status_changeset(%{"status" => status})
           |> Repo.update() do
        {:ok, vote} ->
          {:ok, vote}

        {:error, e} ->
          {:error, e}
      end
    else
      nil ->
        {:error, :not_found}
    end
  end
end
