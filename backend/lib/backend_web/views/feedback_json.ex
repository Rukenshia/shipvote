defmodule BackendWeb.FeedbackView do
  alias Backend.Support.Feedback

  @doc """
  Renders a list of feedback.
  """
  def index(%{feedback: feedback}) do
    %{data: for(feedback <- feedback, do: data(feedback))}
  end

  @doc """
  Renders a single feedback.
  """
  def show(%{feedback: feedback}) do
    %{data: data(feedback)}
  end

  defp data(%Feedback{} = feedback) do
    %{
      id: feedback.id,
      message: feedback.message
    }
  end
end
