defmodule BackendWeb.FeedbackController do
  use BackendWeb, :controller

  alias Appsignal.Logger

  alias Backend.Support
  alias Backend.Support.Feedback

  action_fallback BackendWeb.FallbackController

  def index(conn, _params) do
    feedback = Support.list_feedback()
    render(conn, :index, feedback: feedback)
  end

  def create(conn, %{"feedback" => feedback_params}) do
    with {:ok, %Feedback{} = feedback} <- Support.create_feedback(feedback_params) do
      Logger.warning("application", "Feedback created: #{feedback.message}")
      conn
      |> put_status(:created)
      |> render(:show, feedback: feedback)
    end
  end

  def show(conn, %{"id" => id}) do
    feedback = Support.get_feedback!(id)
    render(conn, :show, feedback: feedback)
  end

  def update(conn, %{"id" => id, "feedback" => feedback_params}) do
    feedback = Support.get_feedback!(id)

    with {:ok, %Feedback{} = feedback} <- Support.update_feedback(feedback, feedback_params) do
      render(conn, :show, feedback: feedback)
    end
  end

  def delete(conn, %{"id" => id}) do
    feedback = Support.get_feedback!(id)

    with {:ok, %Feedback{}} <- Support.delete_feedback(feedback) do
      send_resp(conn, :no_content, "")
    end
  end
end
