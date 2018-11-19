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
      # Because we can't error in a transaction (db aborts the transaction, duh), we filter out
      # ships that don't exist by getting all ships that are in that list
      ships =
        from(s in Backend.Wows.Warship, where: s.id in ^ships)
        |> Repo.all()

      Repo.transaction(fn ->
        from(s in Backend.Stream.ChannelShip, where: s.channel_id == ^channel.id)
        |> Repo.delete_all()

        Logger.debug("update_channel_ships.inserting.ships=#{ships |> length}")

        for ship <- ships do
          Logger.debug("update_channel_ships.inserting.channel_id=#{channel.id},ship=#{ship.id}")

          %Backend.Stream.ChannelShip{}
          |> Backend.Stream.ChannelShip.changeset(%{channel_id: channel.id, ship_id: ship.id})
          |> Repo.insert()
        end
      end)

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
end
