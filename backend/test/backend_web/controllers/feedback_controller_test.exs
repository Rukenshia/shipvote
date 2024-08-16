defmodule BackendWeb.FeedbackControllerTest do
  use BackendWeb.ConnCase

  import Backend.SupportFixtures

  alias Backend.Support.Feedback

  @create_attrs %{
    message: "some message"
  }
  @update_attrs %{
    message: "some updated message"
  }
  @invalid_attrs %{message: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all feedback", %{conn: conn} do
      conn = get(conn, ~p"/api/feedback")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create feedback" do
    test "renders feedback when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/feedback", feedback: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/feedback/#{id}")

      assert %{
               "id" => ^id,
               "message" => "some message"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/feedback", feedback: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update feedback" do
    setup [:create_feedback]

    test "renders feedback when data is valid", %{conn: conn, feedback: %Feedback{id: id} = feedback} do
      conn = put(conn, ~p"/api/feedback/#{feedback}", feedback: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/feedback/#{id}")

      assert %{
               "id" => ^id,
               "message" => "some updated message"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, feedback: feedback} do
      conn = put(conn, ~p"/api/feedback/#{feedback}", feedback: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete feedback" do
    setup [:create_feedback]

    test "deletes chosen feedback", %{conn: conn, feedback: feedback} do
      conn = delete(conn, ~p"/api/feedback/#{feedback}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/feedback/#{feedback}")
      end
    end
  end

  defp create_feedback(_) do
    feedback = feedback_fixture()
    %{feedback: feedback}
  end
end
