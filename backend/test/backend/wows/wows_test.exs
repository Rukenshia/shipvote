defmodule Backend.WowsTest do
  use Backend.DataCase

  alias Backend.Wows

  describe "warships" do
    alias Backend.Wows.Warship

    @valid_attrs %{name: "some name", premium: true, tier: 42}
    @update_attrs %{name: "some updated name", premium: false, tier: 43}
    @invalid_attrs %{name: nil, premium: nil, tier: nil}

    def warship_fixture(attrs \\ %{}) do
      {:ok, warship} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Wows.create_warship()

      warship
    end

    test "list_warships/0 returns all warships" do
      warship = warship_fixture()
      assert Wows.list_warships() == [warship]
    end

    test "get_warship!/1 returns the warship with given id" do
      warship = warship_fixture()
      assert Wows.get_warship!(warship.id) == warship
    end

    test "create_warship/1 with valid data creates a warship" do
      assert {:ok, %Warship{} = warship} = Wows.create_warship(@valid_attrs)
      assert warship.name == "some name"
      assert warship.premium == true
      assert warship.tier == 42
    end

    test "create_warship/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Wows.create_warship(@invalid_attrs)
    end

    test "update_warship/2 with valid data updates the warship" do
      warship = warship_fixture()
      assert {:ok, warship} = Wows.update_warship(warship, @update_attrs)
      assert %Warship{} = warship
      assert warship.name == "some updated name"
      assert warship.premium == false
      assert warship.tier == 43
    end

    test "update_warship/2 with invalid data returns error changeset" do
      warship = warship_fixture()
      assert {:error, %Ecto.Changeset{}} = Wows.update_warship(warship, @invalid_attrs)
      assert warship == Wows.get_warship!(warship.id)
    end

    test "delete_warship/1 deletes the warship" do
      warship = warship_fixture()
      assert {:ok, %Warship{}} = Wows.delete_warship(warship)
      assert_raise Ecto.NoResultsError, fn -> Wows.get_warship!(warship.id) end
    end

    test "change_warship/1 returns a warship changeset" do
      warship = warship_fixture()
      assert %Ecto.Changeset{} = Wows.change_warship(warship)
    end
  end
end
