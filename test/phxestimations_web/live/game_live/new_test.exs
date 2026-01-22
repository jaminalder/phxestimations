defmodule PhxestimationsWeb.GameLive.NewTest do
  use PhxestimationsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "New game page" do
    test "renders create game form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/games/new")

      assert html =~ "Create New Game"
      assert html =~ "Game Name"
      assert html =~ "Voting System"
      assert has_element?(view, "#new-game-page")
      assert has_element?(view, "#new-game-form")
      assert has_element?(view, "#create-game-btn")
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

    test "creates game with fibonacci deck and redirects to join", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/new")

      result =
        view
        |> form("#new-game-form", %{name: "Test Game", deck_type: "fibonacci"})
        |> render_submit()

      # Should redirect to join page (path pattern: /games/:id/join)
      assert {:error, {:live_redirect, %{to: "/games/" <> rest}}} = result
      assert String.ends_with?(rest, "/join")
    end

    test "creates game with tshirt deck and redirects to join", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/new")

      result =
        view
        |> form("#new-game-form", %{name: "Sizing Session", deck_type: "tshirt"})
        |> render_submit()

      # Should redirect to join page
      assert {:error, {:live_redirect, %{to: "/games/" <> rest}}} = result
      assert String.ends_with?(rest, "/join")
    end

    test "creates game with empty name (auto-generates)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/games/new")

      result =
        view
        |> form("#new-game-form", %{name: "", deck_type: "fibonacci"})
        |> render_submit()

      # Should redirect to join page
      assert {:error, {:live_redirect, %{to: "/games/" <> rest}}} = result
      assert String.ends_with?(rest, "/join")
    end
  end
end
