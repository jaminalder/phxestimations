defmodule PhxestimationsWeb.Integration.InviteFlowTest do
  use PhxestimationsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "invite modal" do
    setup do
      %{game_id: game_id, users: [user]} = setup_game_with_voters(1)
      {:ok, view, _html} = live(user.conn, ~p"/games/#{game_id}")
      %{game_id: game_id, view: view}
    end

    test "invite button shows modal", %{view: view} do
      refute has_element?(view, "#invite-modal")

      show_invite_via_view(view)

      assert has_element?(view, "#invite-modal")
    end

    test "modal contains game join URL", %{view: view, game_id: game_id} do
      show_invite_via_view(view)

      assert has_element?(view, "#invite-link")
      html = render(view)
      assert html =~ "/games/#{game_id}/join"
    end

    test "close button hides modal", %{view: view} do
      show_invite_via_view(view)
      assert has_element?(view, "#invite-modal")

      view |> element("#close-invite-btn") |> render_click()

      refute has_element?(view, "#invite-modal")
    end
  end
end
