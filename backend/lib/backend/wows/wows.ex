defmodule Backend.Wows do
  @moduledoc """
  The Wows context.
  """

  import Ecto.Query, warn: false
  alias Backend.Repo

  alias Backend.Wows.Warship

  @doc """
  Returns the list of warships.

  ## Examples

      iex> list_warships()
      [%Warship{}, ...]

  """
  def list_warships do
    Repo.all(Warship)
  end

  @doc """
  Gets a single warship.

  Raises `Ecto.NoResultsError` if the Warship does not exist.

  ## Examples

      iex> get_warship!(123)
      %Warship{}

      iex> get_warship!(456)
      ** (Ecto.NoResultsError)

  """
  def get_warship!(id), do: Repo.get!(Warship, id)

  @doc """
  Creates a warship.

  ## Examples

      iex> create_warship(%{field: value})
      {:ok, %Warship{}}

      iex> create_warship(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_warship(attrs \\ %{}) do
    %Warship{}
    |> Warship.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a warship.

  ## Examples

      iex> update_warship(warship, %{field: new_value})
      {:ok, %Warship{}}

      iex> update_warship(warship, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_warship(%Warship{} = warship, attrs) do
    warship
    |> Warship.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Warship.

  ## Examples

      iex> delete_warship(warship)
      {:ok, %Warship{}}

      iex> delete_warship(warship)
      {:error, %Ecto.Changeset{}}

  """
  def delete_warship(%Warship{} = warship) do
    Repo.delete(warship)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking warship changes.

  ## Examples

      iex> change_warship(warship)
      %Ecto.Changeset{source: %Warship{}}

  """
  def change_warship(%Warship{} = warship) do
    Warship.changeset(warship, %{})
  end
end
