defmodule PhxestimationsWeb.HomeLiveTest do
  use PhxestimationsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Home page" do
    test "renders landing page", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")

      assert html =~ "Planning Poker"
      assert html =~ "Easy-to-use estimation for agile teams"
      assert has_element?(view, "#home-page")
      assert has_element?(view, "#start-game-btn")
    end

    test "displays feature cards", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Real-time"
      assert html =~ "Just Share a Link"
      assert html =~ "Spectator Mode"
    end

    test "start game button navigates to new game page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert {:ok, _view, html} =
               view
               |> element("#start-game-btn")
               |> render_click()
               |> follow_redirect(conn, ~p"/games/new")

      assert html =~ "Create New Game"
    end
  end
end
