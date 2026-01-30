defmodule PhxestimationsWeb.Integration.SpectatorModeTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "spectator mode" do
    setup do
      %{game_id: game_id, voters: voters, spectators: spectators} =
        setup_game_with_mixed(3, 1, spectator_names: ["Observer"])

      %{game_id: game_id, voters: voters, spectators: spectators}
    end

    test "spectator cannot see card deck", %{game_id: game_id, spectators: [spec]} do
      {:ok, view, _html} = live(spec.conn, ~p"/games/#{game_id}")

      refute has_element?(view, "#card-deck")
    end

    test "spectator sees all participants", %{
      game_id: game_id,
      spectators: [spec]
    } do
      {:ok, view, _html} = live(spec.conn, ~p"/games/#{game_id}")

      assert_participant_visible(view, "Alice")
      assert_participant_visible(view, "Bob")
      assert_participant_visible(view, "Charlie")
    end

    test "spectator sees revealed votes and statistics", %{
      game_id: game_id,
      voters: [v1, v2, v3],
      spectators: [spec]
    } do
      # Connect everyone
      {:ok, sv, _} = live(spec.conn, ~p"/games/#{game_id}")
      {:ok, vv1, _} = live(v1.conn, ~p"/games/#{game_id}")
      {:ok, vv2, _} = live(v2.conn, ~p"/games/#{game_id}")
      {:ok, vv3, _} = live(v3.conn, ~p"/games/#{game_id}")

      # All voters vote
      vote_via_view(vv1, "5")
      vote_via_view(vv2, "8")
      vote_via_view(vv3, "5")

      # Reveal
      reveal_via_view(vv1)

      # Spectator sees revealed state
      assert_revealed_state(sv)
      assert_average_displayed(sv, 6.0)
    end

    test "spectator is shown as a participant card", %{
      game_id: game_id,
      spectators: [spec]
    } do
      {:ok, _view, html} = live(spec.conn, ~p"/games/#{game_id}")

      assert html =~ "Observer"
    end

    test "spectator does not count toward voter total", %{
      game_id: game_id,
      voters: voters,
      spectators: [spec]
    } do
      # Connect everyone
      {:ok, sv, _} = live(spec.conn, ~p"/games/#{game_id}")
      for v <- voters, do: live(v.conn, ~p"/games/#{game_id}")

      # Spectator view should show "X / 3" not "X / 4"
      html = render(sv)
      assert html =~ "/ 3"
      refute html =~ "/ 4"
    end
  end
end
