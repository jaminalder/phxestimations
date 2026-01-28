defmodule PhxestimationsWeb.Integration.DeckTypesTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Phxestimations.Poker

  describe "fibonacci deck" do
    setup do
      %{game_id: game_id, users: [user]} = setup_game_with_voters(1, deck_type: :fibonacci)
      {:ok, view, _html} = live(user.conn, ~p"/games/#{game_id}")
      %{game_id: game_id, user: user, view: view}
    end

    test "shows correct fibonacci cards", %{view: view} do
      assert has_element?(view, "#card-0")
      assert has_element?(view, "#card-1")
      assert has_element?(view, "#card-2")
      assert has_element?(view, "#card-3")
      assert has_element?(view, "#card-5")
      assert has_element?(view, "#card-8")
      assert has_element?(view, "#card-13")
      assert has_element?(view, "#card-21")
      assert has_element?(view, "#card-34")
      assert has_element?(view, "#card-55")
      assert has_element?(view, "#card-89")
      assert has_element?(view, "#card-\\?")
      assert has_element?(view, "#card-coffee")
    end

    test "fibonacci deck calculates numeric average", %{game_id: game_id, user: u1} do
      # Add a second voter
      {conn2, pid2} = build_user_conn()
      {:ok, _} = Poker.join_game(game_id, pid2, "Bob", :voter)

      {:ok, v1, _} = live(u1.conn, ~p"/games/#{game_id}")
      {:ok, v2, _} = live(conn2, ~p"/games/#{game_id}")

      vote_via_view(v1, "5")
      vote_via_view(v2, "13")

      reveal_via_view(v1)

      # Average of 5 and 13 = 9.0
      assert_average_displayed(v1, 9.0)
    end
  end

  describe "t-shirt deck" do
    setup do
      %{game_id: game_id, users: [user]} = setup_game_with_voters(1, deck_type: :tshirt)
      {:ok, view, _html} = live(user.conn, ~p"/games/#{game_id}")
      %{game_id: game_id, user: user, view: view}
    end

    test "shows correct t-shirt cards", %{view: view} do
      assert has_element?(view, "#card-XS")
      assert has_element?(view, "#card-S")
      assert has_element?(view, "#card-M")
      assert has_element?(view, "#card-L")
      assert has_element?(view, "#card-XL")
      assert has_element?(view, "#card-XXL")
      assert has_element?(view, "#card-\\?")
      assert has_element?(view, "#card-coffee")
    end

    test "t-shirt deck does NOT show vote average", %{game_id: game_id, user: u1} do
      # Add a second voter
      {conn2, pid2} = build_user_conn()
      {:ok, _} = Poker.join_game(game_id, pid2, "Bob", :voter)

      {:ok, v1, _} = live(u1.conn, ~p"/games/#{game_id}")
      {:ok, v2, _} = live(conn2, ~p"/games/#{game_id}")

      vote_via_view(v1, "M")
      vote_via_view(v2, "L")

      reveal_via_view(v1)

      # T-shirt sizes have no numeric average
      refute_average_displayed(v1)
    end
  end
end
