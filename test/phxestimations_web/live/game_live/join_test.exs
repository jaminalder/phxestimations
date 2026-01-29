defmodule PhxestimationsWeb.GameLive.JoinTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Phxestimations.Poker

  describe "Join game page" do
    setup do
      {:ok, game_id} = Poker.create_game("Test Game", :fibonacci)
      %{game_id: game_id}
    end

    test "renders join form for existing game", %{conn: conn, game_id: game_id} do
      {:ok, view, html} = live(conn, ~p"/games/#{game_id}/join")

      assert html =~ "Join Game"
      assert html =~ "Test Game"
      assert html =~ "Fibonacci"
      assert has_element?(view, "#join-game-page")
      assert has_element?(view, "#join-game-form")
      assert has_element?(view, "#join-btn")
    end

    test "shows role options", %{conn: conn, game_id: game_id} do
      {:ok, _view, html} = live(conn, ~p"/games/#{game_id}/join")

      assert html =~ "Voter"
      assert html =~ "Spectator"
    end

    test "has back link to home", %{conn: conn, game_id: game_id} do
      {:ok, view, html} = live(conn, ~p"/games/#{game_id}/join")

      assert html =~ "Back to home"

      assert {:ok, _view, html} =
               view
               |> element("a", "Back to home")
               |> render_click()
               |> follow_redirect(conn, ~p"/")

      assert html =~ "Planning Poker"
    end

    test "uses generated default name when name is empty", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, ~p"/games/#{game_id}/join")

      result =
        view
        |> form("#join-game-form", %{name: "", role: "voter"})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: to}}} = result
      assert to =~ ~r/name=\w+/
    end

    test "joins game as voter and redirects to game room", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, ~p"/games/#{game_id}/join")

      # Get the session to track the participant_id
      result =
        view
        |> form("#join-game-form", %{name: "Alice", role: "voter"})
        |> render_submit()

      # Verify redirect happens
      assert {:error, {:live_redirect, %{to: "/games/" <> _}}} = result

      # Verify participant was added to game
      {:ok, game} = Poker.get_game(game_id)

      assert Enum.any?(game.participants, fn {_id, p} -> p.name == "Alice" && p.role == :voter end)
    end

    test "joins game as spectator and redirects to game room", %{conn: conn, game_id: game_id} do
      {:ok, view, _html} = live(conn, ~p"/games/#{game_id}/join")

      result =
        view
        |> form("#join-game-form", %{name: "Bob", role: "spectator"})
        |> render_submit()

      # Verify redirect happens
      assert {:error, {:live_redirect, %{to: "/games/" <> _}}} = result

      # Verify participant was added as spectator
      {:ok, game} = Poker.get_game(game_id)

      assert Enum.any?(game.participants, fn {_id, p} ->
               p.name == "Bob" && p.role == :spectator
             end)
    end

    test "redirects to home for non-existent game", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Game not found"}}}} =
               live(conn, ~p"/games/nonexistent/join")
    end
  end
end
