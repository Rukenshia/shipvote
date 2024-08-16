defmodule Backend.SupportFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Backend.Support` context.
  """

  @doc """
  Generate a feedback.
  """
  def feedback_fixture(attrs \\ %{}) do
    {:ok, feedback} =
      attrs
      |> Enum.into(%{
        message: "some message"
      })
      |> Backend.Support.create_feedback()

    feedback
  end
end
