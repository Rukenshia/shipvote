defmodule Backend.StreamTest do
  use Backend.DataCase

  alias Backend.Stream

  describe "channels" do
    alias Backend.Stream.Channel

    @valid_attrs %{channel_id: 42}
    @update_attrs %{channel_id: 43}
    @invalid_attrs %{channel_id: nil}

    def channel_fixture(attrs \\ %{}) do
      {:ok, channel} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Stream.create_channel()

      channel
    end

    test "list_channels/0 returns all channels" do
      channel = channel_fixture()
      assert Stream.list_channels() == [channel]
    end

    test "get_channel!/1 returns the channel with given id" do
      channel = channel_fixture()
      assert Stream.get_channel!(channel.id) == channel
    end

    test "create_channel/1 with valid data creates a channel" do
      assert {:ok, %Channel{} = channel} = Stream.create_channel(@valid_attrs)
      assert channel.channel_id == 42
    end

    test "create_channel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stream.create_channel(@invalid_attrs)
    end

    test "update_channel/2 with valid data updates the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{} = channel} = Stream.update_channel(channel, @update_attrs)
      assert channel.channel_id == 43
    end

    test "update_channel/2 with invalid data returns error changeset" do
      channel = channel_fixture()
      assert {:error, %Ecto.Changeset{}} = Stream.update_channel(channel, @invalid_attrs)
      assert channel == Stream.get_channel!(channel.id)
    end

    test "delete_channel/1 deletes the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{}} = Stream.delete_channel(channel)
      assert_raise Ecto.NoResultsError, fn -> Stream.get_channel!(channel.id) end
    end

    test "change_channel/1 returns a channel changeset" do
      channel = channel_fixture()
      assert %Ecto.Changeset{} = Stream.change_channel(channel)
    end
  end

  describe "channel_ships" do
    alias Backend.Stream.ChannelShip

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def channel_ship_fixture(attrs \\ %{}) do
      {:ok, channel_ship} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Stream.create_channel_ship()

      channel_ship
    end

    test "list_channel_ships/0 returns all channel_ships" do
      channel_ship = channel_ship_fixture()
      assert Stream.list_channel_ships() == [channel_ship]
    end

    test "get_channel_ship!/1 returns the channel_ship with given id" do
      channel_ship = channel_ship_fixture()
      assert Stream.get_channel_ship!(channel_ship.id) == channel_ship
    end

    test "create_channel_ship/1 with valid data creates a channel_ship" do
      assert {:ok, %ChannelShip{} = channel_ship} = Stream.create_channel_ship(@valid_attrs)
    end

    test "create_channel_ship/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stream.create_channel_ship(@invalid_attrs)
    end

    test "update_channel_ship/2 with valid data updates the channel_ship" do
      channel_ship = channel_ship_fixture()
      assert {:ok, %ChannelShip{} = channel_ship} = Stream.update_channel_ship(channel_ship, @update_attrs)
    end

    test "update_channel_ship/2 with invalid data returns error changeset" do
      channel_ship = channel_ship_fixture()
      assert {:error, %Ecto.Changeset{}} = Stream.update_channel_ship(channel_ship, @invalid_attrs)
      assert channel_ship == Stream.get_channel_ship!(channel_ship.id)
    end

    test "delete_channel_ship/1 deletes the channel_ship" do
      channel_ship = channel_ship_fixture()
      assert {:ok, %ChannelShip{}} = Stream.delete_channel_ship(channel_ship)
      assert_raise Ecto.NoResultsError, fn -> Stream.get_channel_ship!(channel_ship.id) end
    end

    test "change_channel_ship/1 returns a channel_ship changeset" do
      channel_ship = channel_ship_fixture()
      assert %Ecto.Changeset{} = Stream.change_channel_ship(channel_ship)
    end
  end
end
