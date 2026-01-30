defmodule PhxestimationsWeb.Integration.EdgeCasesTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Phxestimations.Poker

  describe "join mid-vote" do
    test "new user joining while voting in progress can vote immediately" do
      %{game_id: game_id, users: [u1, u2]} = setup_game_with_voters(2)

      # First two users connect and start voting
      [%{view: v1}, %{view: _v2}] = connect_users_to_game([u1, u2], game_id)
      vote_via_view(v1, "5")

      # New user joins mid-vote
      {conn3, pid3} = build_user_conn()
      {:ok, _game} = Poker.join_game(game_id, pid3, "LateComer", :voter)
      {:ok, v3, _html} = live(conn3, ~p"/games/#{game_id}")

      # New user can see card deck and vote
      assert has_element?(v3, "#card-deck")
      vote_via_view(v3, "8")

      {:ok, game} = Poker.get_game(game_id)
      assert game.participants[pid3].vote == "8"
    end
  end

  describe "join after reveal" do
    test "new user joining after reveal sees revealed state" do
      %{game_id: game_id, users: [u1, u2]} = setup_game_with_voters(2)

      [%{view: v1}, %{view: v2}] = connect_users_to_game([u1, u2], game_id)

      # Vote (auto-reveals when all voted)
      vote_via_view(v1, "5")
      vote_via_view(v2, "8")

      # New user joins after auto-reveal
      {conn3, pid3} = build_user_conn()
      {:ok, _game} = Poker.join_game(game_id, pid3, "LateComer", :voter)
      {:ok, v3, _html} = live(conn3, ~p"/games/#{game_id}")

      # New user sees revealed state
      assert_revealed_state(v3)
    end
  end

  describe "vote after reveal" do
    test "casting vote after reveal returns error via API" do
      %{game_id: game_id, users: [u1]} = setup_game_with_voters(1)
      [%{view: _v1}] = connect_users_to_game([u1], game_id)

      # Single voter - vote auto-reveals
      Poker.cast_vote(game_id, u1.participant_id, "5")

      # Try to vote via API after auto-reveal
      result = Poker.cast_vote(game_id, u1.participant_id, "8")
      assert {:error, :already_revealed} = result
    end
  end

  describe "empty reveal" do
    test "reveal with no votes shows no average" do
      %{game_id: game_id, users: [u1]} = setup_game_with_voters(1)
      [%{view: v1}] = connect_users_to_game([u1], game_id)

      # Reveal without anyone voting (force via API since button might be disabled)
      {:ok, _game} = Poker.reveal_votes(game_id)

      # Should show revealed state but no average
      assert_revealed_state(v1)
      refute_average_displayed(v1)
    end
  end
end
