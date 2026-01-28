defmodule PhxestimationsWeb.Integration.GameLifecycleTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Phxestimations.Poker

  describe "full game lifecycle" do
    test "create game via New LiveView, join, vote, reveal, reset", %{conn: conn} do
      # Step 1: Create game via form
      {:ok, new_view, _html} = live(conn, ~p"/games/new")

      {:ok, join_view, html} =
        new_view
        |> form("#new-game-form", %{name: "Lifecycle Test", deck_type: "fibonacci"})
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ "Lifecycle Test"
      assert html =~ "Join Game"

      # Step 2: First user joins via join form
      result =
        join_view
        |> form("#join-game-form", %{name: "Alice", role: "voter"})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: "/games/" <> _rest}}} = result
    end

    test "3 users join, vote, reveal with stats, then reset", %{conn: _conn} do
      %{game_id: game_id, users: [u1, u2, u3]} = setup_game_with_voters(3)

      # Mount all 3 LiveViews
      [%{view: v1}, %{view: v2}, %{view: v3}] = connect_users_to_game([u1, u2, u3], game_id)

      # All users see each other
      assert_participant_visible(v1, "Alice")
      assert_participant_visible(v1, "Bob")
      assert_participant_visible(v1, "Charlie")

      assert_participant_visible(v2, "Alice")
      assert_participant_visible(v3, "Bob")

      # All vote
      vote_via_view(v1, "5")
      vote_via_view(v2, "8")
      vote_via_view(v3, "5")

      # Verify vote count propagates (check via API since PubSub is async)
      {:ok, game} = Poker.get_game(game_id)
      voted = Enum.count(game.participants, fn {_id, p} -> p.vote != nil end)
      assert voted == 3

      # Reveal
      reveal_via_view(v1)

      # All views show revealed state
      assert_revealed_state(v1)
      assert_revealed_state(v2)
      assert_revealed_state(v3)

      # Average: (5 + 8 + 5) / 3 = 6.0
      assert_average_displayed(v1, 6.0)
      assert_average_displayed(v2, 6.0)

      # New round
      reset_via_view(v1)

      # All views return to voting state
      assert_voting_state(v1)
      assert_voting_state(v2)
      assert_voting_state(v3)

      # Votes cleared in state
      {:ok, game} = Poker.get_game(game_id)
      voters = Enum.filter(game.participants, fn {_id, p} -> p.role == :voter end)
      assert Enum.all?(voters, fn {_id, p} -> p.vote == nil end)
    end
  end
end
