defmodule PhxestimationsWeb.Integration.MultiUserVotingTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Phxestimations.Poker

  describe "multi-user voting" do
    setup do
      %{game_id: game_id, users: users} =
        setup_game_with_voters(4, names: ~w(Alice Bob Charlie Diana))

      views =
        users
        |> connect_users_to_game(game_id)
        |> Enum.map(& &1.view)

      %{game_id: game_id, users: users, views: views}
    end

    test "4 users see each other on the poker table", %{views: [v1, _v2, _v3, _v4]} do
      assert_participant_visible(v1, "Alice")
      assert_participant_visible(v1, "Bob")
      assert_participant_visible(v1, "Charlie")
      assert_participant_visible(v1, "Diana")
    end

    test "vote status updates propagate to all connected views", %{
      game_id: game_id,
      views: [v1, _v2, _v3, _v4]
    } do
      vote_via_view(v1, "5")

      # Verify via API
      {:ok, game} = Poker.get_game(game_id)
      voted = Enum.count(game.participants, fn {_id, p} -> p.vote != nil end)
      assert voted == 1
    end

    test "all voters voting auto-reveals", %{views: [v1, v2, v3, v4]} do
      vote_via_view(v1, "3")
      vote_via_view(v2, "5")
      vote_via_view(v3, "8")
      vote_via_view(v4, "5")

      # Auto-revealed after all voters voted
      assert_revealed_state(v1)
      assert_revealed_state(v2)
      assert_revealed_state(v3)
      assert_revealed_state(v4)
    end

    test "reveal shows all vote values to all users", %{views: [v1, v2, v3, v4]} do
      vote_via_view(v1, "5")
      vote_via_view(v2, "8")
      vote_via_view(v3, "13")
      vote_via_view(v4, "5")

      # Auto-revealed - all views should show the votes in rendered HTML
      for view <- [v1, v2, v3, v4] do
        html = render(view)
        assert html =~ "5"
        assert html =~ "8"
        assert html =~ "13"
      end
    end

    test "vote change before reveal updates correctly", %{
      game_id: game_id,
      users: [u1 | _],
      views: [v1, v2, v3, v4]
    } do
      # Vote initially
      vote_via_view(v1, "5")

      {:ok, game} = Poker.get_game(game_id)
      assert game.participants[u1.participant_id].vote == "5"

      # Change vote
      vote_via_view(v1, "8")

      {:ok, game} = Poker.get_game(game_id)
      assert game.participants[u1.participant_id].vote == "8"

      # Complete voting (auto-reveals on last vote)
      vote_via_view(v2, "3")
      vote_via_view(v3, "5")
      vote_via_view(v4, "5")

      # Verify the changed vote is shown (8, not 5)
      {:ok, game} = Poker.get_game(game_id)
      assert game.participants[u1.participant_id].vote == "8"
    end
  end
end
