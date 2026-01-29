defmodule PhxestimationsWeb.GameLive.NewTest do
  use PhxestimationsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "New game page" do
    test "renders create game form with player name and role fields", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/games/new")

      assert html =~ "Create New Game"
      assert html =~ "Game Name"
      assert html =~ "Voting System"
      assert html =~ "Your Name"
      assert html =~ "Your Role"
      assert html =~ "Voter"
      assert html =~ "Spectator"
      assert has_element?(view, "#new-game-page")
      assert has_element?(view, "#new-game-form")
      assert has_element?(view, "#create-game-btn")
      assert has_element?(view, "#player-name")
    end

    test "shows deck type options", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/games/new")

      assert html =~ "Fibonacci"
      assert html =~ "T-Shirt Sizes"
    end

    test "has back link to home", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/games/new")

      assert html =~ "Back to home"

      assert {:ok, _view, html} =
               view
               |> element("a", "Back to home")
               |> render_click()
               |> follow_redirect(conn, ~p"/")

      assert html =~ "Planning Poker"
    end

    test "creates game with fibonacci deck and redirects to game room", %{conn: conn} do
      conn = get(conn, ~p"/")
      {:ok, view, _html} = live(conn, ~p"/games/new")

      {:ok, game_view, game_html} =
        view
        |> form("#new-game-form", %{
          name: "Test Game",
          deck_type: "fibonacci",
          player_name: "Alice"
        })
        |> render_submit()
        |> follow_redirect(conn)

      assert game_html =~ "Alice"
      assert has_element?(game_view, "#game-room")
      assert has_element?(game_view, "#card-deck")
    end

    test "creates game with tshirt deck and redirects to game room", %{conn: conn} do
      conn = get(conn, ~p"/")
      {:ok, view, _html} = live(conn, ~p"/games/new")

      {:ok, game_view, game_html} =
        view
        |> form("#new-game-form", %{
          name: "Sizing Session",
          deck_type: "tshirt",
          player_name: "Bob"
        })
        |> render_submit()
        |> follow_redirect(conn)

      assert game_html =~ "Bob"
      assert has_element?(game_view, "#game-room")
      assert has_element?(game_view, "#card-deck")
    end

    test "creates game with empty name (auto-generates)", %{conn: conn} do
      conn = get(conn, ~p"/")
      {:ok, view, _html} = live(conn, ~p"/games/new")

      {:ok, game_view, _game_html} =
        view
        |> form("#new-game-form", %{name: "", deck_type: "fibonacci", player_name: "Charlie"})
        |> render_submit()
        |> follow_redirect(conn)

      assert has_element?(game_view, "#game-room")
      assert has_element?(game_view, "#card-deck")
    end

    test "creates game as spectator and lands in game room without card deck", %{conn: conn} do
      conn = get(conn, ~p"/")
      {:ok, view, _html} = live(conn, ~p"/games/new")

      {:ok, game_view, game_html} =
        view
        |> form("#new-game-form", %{
          name: "Spectator Game",
          deck_type: "fibonacci",
          player_name: "Dana",
          role: "spectator"
        })
        |> render_submit()
        |> follow_redirect(conn)

      assert game_html =~ "Dana"
      assert has_element?(game_view, "#game-room")
      refute has_element?(game_view, "#card-deck")
    end

    test "uses generated default name when player name is empty", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/new")

      result =
        view
        |> form("#new-game-form", %{name: "Test Game", deck_type: "fibonacci", player_name: ""})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: to}}} = result
      assert to =~ ~r/name=\w+/
    end

    test "uses generated default name when player name is whitespace-only", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/new")

      result =
        view
        |> form("#new-game-form", %{
          name: "Test Game",
          deck_type: "fibonacci",
          player_name: "   "
        })
        |> render_submit()

      assert {:error, {:live_redirect, %{to: to}}} = result
      assert to =~ ~r/name=\w+/
    end
  end
end
