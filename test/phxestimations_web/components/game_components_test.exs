defmodule PhxestimationsWeb.GameComponentsTest do
  use PhxestimationsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias PhxestimationsWeb.GameComponents
  alias Phxestimations.Poker.Participant

  describe "poker_card/1" do
    test "renders unselected card" do
      html = render_component(&GameComponents.poker_card/1, card: "5", selected: false)

      assert html =~ "5"
      assert html =~ ~s(id="card-5")
      assert html =~ "bg-slate-700/50"
    end

    test "renders selected card" do
      html = render_component(&GameComponents.poker_card/1, card: "8", selected: true)

      assert html =~ "8"
      assert html =~ "from-blue-500"
    end

    test "renders disabled card" do
      html =
        render_component(&GameComponents.poker_card/1,
          card: "13",
          selected: false,
          disabled: true
        )

      assert html =~ "disabled"
      assert html =~ "opacity-50"
    end
  end

  describe "participant_card/1" do
    test "renders participant without vote" do
      participant = Participant.new("p1", "Alice", :voter)

      html =
        render_component(&GameComponents.participant_card/1,
          participant: participant,
          current_user?: false,
          revealed?: false
        )

      assert html =~ "Alice"
      assert html =~ ~s(id="participant-p1")
      assert html =~ "?"
    end

    test "renders participant with vote (hidden)" do
      participant = Participant.new("p1", "Bob", :voter) |> Participant.vote("5")

      html =
        render_component(&GameComponents.participant_card/1,
          participant: participant,
          current_user?: false,
          revealed?: false
        )

      assert html =~ "Bob"
      assert html =~ "hero-check"
      refute html =~ ">5<"
    end

    test "renders participant with revealed vote" do
      participant = Participant.new("p1", "Charlie", :voter) |> Participant.vote("8")

      html =
        render_component(&GameComponents.participant_card/1,
          participant: participant,
          current_user?: false,
          revealed?: true
        )

      assert html =~ "Charlie"
      assert html =~ "8"
      assert html =~ "from-emerald-500"
    end

    test "marks current user" do
      participant = Participant.new("p1", "Me", :voter)

      html =
        render_component(&GameComponents.participant_card/1,
          participant: participant,
          current_user?: true,
          revealed?: false
        )

      assert html =~ "(you)"
      assert html =~ "border-blue-500/50"
    end

    test "shows disconnected state" do
      participant =
        Participant.new("p1", "Disconnected", :voter) |> Participant.set_connected(false)

      html =
        render_component(&GameComponents.participant_card/1,
          participant: participant,
          current_user?: false,
          revealed?: false
        )

      assert html =~ "disconnected"
      assert html =~ "opacity-50"
    end
  end

  describe "voting_status/1" do
    test "renders voting progress" do
      html =
        render_component(&GameComponents.voting_status/1,
          state: :voting,
          vote_count: 2,
          total_voters: 5
        )

      assert html =~ "2"
      assert html =~ "5"
      assert html =~ "voted"
    end

    test "renders revealed state" do
      html =
        render_component(&GameComponents.voting_status/1,
          state: :revealed,
          vote_count: 5,
          total_voters: 5
        )

      assert html =~ "Votes Revealed!"
    end

    test "renders statistics when provided" do
      html =
        render_component(&GameComponents.voting_status/1,
          state: :revealed,
          vote_count: 3,
          total_voters: 3,
          statistics: %{average: 5.0, distribution: %{"5" => 2, "8" => 1}}
        )

      assert html =~ "vote-statistics"
      assert html =~ "vote-average"
      assert html =~ "5.0"
    end
  end

  describe "game_controls/1" do
    test "renders reveal button when voting" do
      html = render_component(&GameComponents.game_controls/1, state: :voting, all_voted?: true)

      assert html =~ ~s(id="reveal-btn")
      assert html =~ "Reveal Votes"
      assert html =~ "bg-emerald-500"
    end

    test "disables reveal button when not all voted" do
      html = render_component(&GameComponents.game_controls/1, state: :voting, all_voted?: false)

      assert html =~ "disabled"
      assert html =~ "cursor-not-allowed"
    end

    test "renders reset button when revealed" do
      html = render_component(&GameComponents.game_controls/1, state: :revealed, all_voted?: true)

      assert html =~ ~s(id="reset-btn")
      assert html =~ "New Round"
    end
  end
end
