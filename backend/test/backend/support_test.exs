defmodule Backend.SupportTest do
  use Backend.DataCase

  alias Backend.Support

  describe "feedback" do
    alias Backend.Support.Feedback

    import Backend.SupportFixtures

    @invalid_attrs %{message: nil}

    test "list_feedback/0 returns all feedback" do
      feedback = feedback_fixture()
      assert Support.list_feedback() == [feedback]
    end

    test "get_feedback!/1 returns the feedback with given id" do
      feedback = feedback_fixture()
      assert Support.get_feedback!(feedback.id) == feedback
    end

    test "create_feedback/1 with valid data creates a feedback" do
      valid_attrs = %{message: "some message"}

      assert {:ok, %Feedback{} = feedback} = Support.create_feedback(valid_attrs)
      assert feedback.message == "some message"
    end

    test "create_feedback/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Support.create_feedback(@invalid_attrs)
    end

    test "update_feedback/2 with valid data updates the feedback" do
      feedback = feedback_fixture()
      update_attrs = %{message: "some updated message"}

      assert {:ok, %Feedback{} = feedback} = Support.update_feedback(feedback, update_attrs)
      assert feedback.message == "some updated message"
    end

    test "update_feedback/2 with invalid data returns error changeset" do
      feedback = feedback_fixture()
      assert {:error, %Ecto.Changeset{}} = Support.update_feedback(feedback, @invalid_attrs)
      assert feedback == Support.get_feedback!(feedback.id)
    end

    test "delete_feedback/1 deletes the feedback" do
      feedback = feedback_fixture()
      assert {:ok, %Feedback{}} = Support.delete_feedback(feedback)
      assert_raise Ecto.NoResultsError, fn -> Support.get_feedback!(feedback.id) end
    end

    test "change_feedback/1 returns a feedback changeset" do
      feedback = feedback_fixture()
      assert %Ecto.Changeset{} = Support.change_feedback(feedback)
    end
  end
end
