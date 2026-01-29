defmodule PhxestimationsWeb.Integration.StoryFlowTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Phxestimations.Poker

  describe "story name flow" do
    setup do
      %{game_id: game_id, users: users} = setup_game_with_voters(2)
      %{game_id: game_id, users: users}
    end

    test "set story name is visible to all users", %{game_id: game_id, users: [u1, u2]} do
      [%{view: v1}, %{view: v2}] = connect_users_to_game([u1, u2], game_id)

      # Set story name via LiveView event
      render_click(v1, "set_story", %{"story" => "PROJ-101: Login"})

      # Both views should see the story name
      html1 = render(v1)
      html2 = render(v2)

      assert html1 =~ "PROJ-101: Login"
      assert html2 =~ "PROJ-101: Login"

      # Verify via API too
      {:ok, game} = Poker.get_game(game_id)
      assert game.story_name == "PROJ-101: Login"
    end

    test "vote, reveal, reset clears story name", %{game_id: game_id, users: [u1, u2]} do
      [%{view: v1}, %{view: v2}] = connect_users_to_game([u1, u2], game_id)

      # Set story, vote, reveal, reset
      render_click(v1, "set_story", %{"story" => "PROJ-102: Signup"})
      vote_via_view(v1, "5")
      vote_via_view(v2, "8")
      reveal_via_view(v1)
      reset_via_view(v1)

      # Story should be cleared
      {:ok, game} = Poker.get_game(game_id)
      assert game.story_name == nil

      # Both views should not show the story name anymore
      html1 = render(v1)
      html2 = render(v2)

      refute html1 =~ "PROJ-102: Signup"
      refute html2 =~ "PROJ-102: Signup"
    end
  end
end
