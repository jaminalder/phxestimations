defmodule PhxestimationsWeb.GameLive.ShowTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Phxestimations.Poker

  describe "Game room" do
    setup %{conn: conn} do
      {:ok, game_id} = Poker.create_game("Test Game", :fibonacci)

      # Get the participant_id that will be assigned by the plug
      conn = get(conn, ~p"/")
      participant_id = get_session(conn, "participant_id")

      %{game_id: game_id, participant_id: participant_id, conn: conn}
    end

    test "redirects to join if not a participant", %{conn: conn, game_id: game_id} do
      assert {:error, {:live_redirect, %{to: "/games/" <> _rest}}} =
               live(conn, ~p"/games/#{game_id}")
    end

    test "renders game room for participant", %{
      conn: conn,
      game_id: game_id,
      participant_id: participant_id
    } do
      # Join the game directly through the API
      {:ok, _game} = Poker.join_game(game_id, participant_id, "Alice", :voter)

      {:ok, view, html} = live(conn, ~p"/games/#{game_id}")

      assert html =~ "Test Game"
      assert html =~ "Alice"
      assert has_element?(view, "#game-room")
      assert has_element?(view, "#game-title")
      assert has_element?(view, "#poker-table")
      assert has_element?(view, "#card-deck")
    end

    test "shows card selection for voters", %{
      conn: conn,
      game_id: game_id,
      participant_id: participant_id
    } do
      {:ok, _game} = Poker.join_game(game_id, participant_id, "Alice", :voter)

      {:ok, view, _html} = live(conn, ~p"/games/#{game_id}")

      # Check that cards are visible
      assert has_element?(view, "#card-5")
      assert has_element?(view, "#card-8")
      assert has_element?(view, "#card-13")
    end

    test "can vote on a card", %{conn: conn, game_id: game_id, participant_id: participant_id} do
      {:ok, _game} = Poker.join_game(game_id, participant_id, "Alice", :voter)

      {:ok, view, _html} = live(conn, ~p"/games/#{game_id}")

      # Vote for a card
      html = view |> element("#card-5") |> render_click()

      # The card should be selected (highlighted)
      assert html =~ "from-blue-500"
    end

    test "shows reveal button when voting", %{
      conn: conn,
      game_id: game_id,
      participant_id: participant_id
    } do
      {:ok, _game} = Poker.join_game(game_id, participant_id, "Alice", :voter)

      {:ok, view, _html} = live(conn, ~p"/games/#{game_id}")

      assert has_element?(view, "#reveal-btn")
    end

    test "redirects to home for non-existent game", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Game not found"}}}} =
               live(conn, ~p"/games/nonexistent")
    end
  end

  describe "Spectator mode" do
    setup %{conn: conn} do
      {:ok, game_id} = Poker.create_game("Test Game", :fibonacci)

      conn = get(conn, ~p"/")
      participant_id = get_session(conn, "participant_id")

      %{game_id: game_id, participant_id: participant_id, conn: conn}
    end

    test "does not show card selection for spectators", %{
      conn: conn,
      game_id: game_id,
      participant_id: participant_id
    } do
      {:ok, _game} = Poker.join_game(game_id, participant_id, "Observer", :spectator)

      {:ok, view, _html} = live(conn, ~p"/games/#{game_id}")

      # Spectators should not see the card deck
      refute has_element?(view, "#card-deck")
    end
  end
end
