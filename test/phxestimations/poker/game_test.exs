defmodule Phxestimations.Poker.GameTest do
  use ExUnit.Case, async: true

  alias Phxestimations.Poker.{Game, Participant}

  defp create_game do
    Game.new("game1", "Sprint Planning", :fibonacci)
  end

  defp add_voters(game, count) do
    Enum.reduce(1..count, game, fn i, acc ->
      participant = Participant.new("p#{i}", "Player #{i}", :voter)
      Game.add_participant(acc, participant)
    end)
  end

  describe "new/3" do
    test "creates a new game" do
      game = Game.new("game1", "Sprint Planning", :fibonacci)

      assert game.id == "game1"
      assert game.name == "Sprint Planning"
      assert game.deck_type == :fibonacci
      assert game.state == :voting
      assert game.story_name == nil
      assert game.participants == %{}
      assert %DateTime{} = game.created_at
    end

    test "creates game with tshirt deck" do
      game = Game.new("game2", "Sizing", :tshirt)

      assert game.deck_type == :tshirt
    end
  end

  describe "add_participant/2" do
    test "adds participant to game" do
      participant = Participant.new("p1", "Alice", :voter)

      game =
        create_game()
        |> Game.add_participant(participant)

      assert Game.participant_count(game) == 1
      assert Game.get_participant(game, "p1") == participant
    end

    test "adds multiple participants" do
      game = create_game() |> add_voters(3)

      assert Game.participant_count(game) == 3
    end
  end

  describe "remove_participant/2" do
    test "removes participant from game" do
      game =
        create_game()
        |> add_voters(2)
        |> Game.remove_participant("p1")

      assert Game.participant_count(game) == 1
      assert Game.get_participant(game, "p1") == nil
      assert Game.get_participant(game, "p2") != nil
    end

    test "handles removing non-existent participant" do
      game = create_game() |> add_voters(1)
      updated = Game.remove_participant(game, "nonexistent")

      assert Game.participant_count(updated) == 1
    end
  end

  describe "cast_vote/3" do
    test "records vote for valid card" do
      game = create_game() |> add_voters(1)
      {:ok, updated} = Game.cast_vote(game, "p1", "5")

      participant = Game.get_participant(updated, "p1")
      assert participant.vote == "5"
    end

    test "allows changing vote" do
      game = create_game() |> add_voters(1)
      {:ok, game} = Game.cast_vote(game, "p1", "5")
      {:ok, updated} = Game.cast_vote(game, "p1", "8")

      participant = Game.get_participant(updated, "p1")
      assert participant.vote == "8"
    end

    test "returns error for invalid card" do
      game = create_game() |> add_voters(1)
      assert {:error, :invalid_card} = Game.cast_vote(game, "p1", "invalid")
    end

    test "returns error when already revealed" do
      game =
        create_game()
        |> add_voters(1)
        |> Game.reveal_votes()

      assert {:error, :already_revealed} = Game.cast_vote(game, "p1", "5")
    end
  end

  describe "reveal_votes/1" do
    test "changes state to revealed" do
      game = create_game() |> add_voters(1)
      revealed = Game.reveal_votes(game)

      assert revealed.state == :revealed
    end

    test "does nothing if already revealed" do
      game =
        create_game()
        |> add_voters(1)
        |> Game.reveal_votes()
        |> Game.reveal_votes()

      assert game.state == :revealed
    end
  end

  describe "reset_round/1" do
    test "resets state to voting" do
      game =
        create_game()
        |> add_voters(1)
        |> Game.reveal_votes()
        |> Game.reset_round()

      assert game.state == :voting
    end

    test "clears all votes" do
      game = create_game() |> add_voters(2)
      {:ok, game} = Game.cast_vote(game, "p1", "5")
      {:ok, game} = Game.cast_vote(game, "p2", "8")

      reset = Game.reset_round(game)

      refute Participant.voted?(Game.get_participant(reset, "p1"))
      refute Participant.voted?(Game.get_participant(reset, "p2"))
    end

    test "clears story name" do
      game =
        create_game()
        |> Game.set_story_name("JIRA-123")
        |> Game.reset_round()

      assert game.story_name == nil
    end
  end

  describe "set_story_name/2" do
    test "sets story name" do
      game =
        create_game()
        |> Game.set_story_name("JIRA-123")

      assert game.story_name == "JIRA-123"
    end

    test "can clear story name" do
      game =
        create_game()
        |> Game.set_story_name("JIRA-123")
        |> Game.set_story_name(nil)

      assert game.story_name == nil
    end
  end

  describe "voters/1 and spectators/1" do
    test "returns only voters" do
      voter = Participant.new("v1", "Voter", :voter)
      spectator = Participant.new("s1", "Spectator", :spectator)

      game =
        create_game()
        |> Game.add_participant(voter)
        |> Game.add_participant(spectator)

      voters = Game.voters(game)
      assert length(voters) == 1
      assert hd(voters).role == :voter
    end

    test "returns only spectators" do
      voter = Participant.new("v1", "Voter", :voter)
      spectator = Participant.new("s1", "Spectator", :spectator)

      game =
        create_game()
        |> Game.add_participant(voter)
        |> Game.add_participant(spectator)

      spectators = Game.spectators(game)
      assert length(spectators) == 1
      assert hd(spectators).role == :spectator
    end
  end

  describe "all_voters_voted?/1" do
    test "returns true when all voters have voted" do
      game = create_game() |> add_voters(2)
      {:ok, game} = Game.cast_vote(game, "p1", "5")
      {:ok, game} = Game.cast_vote(game, "p2", "8")

      assert Game.all_voters_voted?(game)
    end

    test "returns false when some voters haven't voted" do
      game = create_game() |> add_voters(2)
      {:ok, game} = Game.cast_vote(game, "p1", "5")

      refute Game.all_voters_voted?(game)
    end

    test "returns false when no voters" do
      game = create_game()
      refute Game.all_voters_voted?(game)
    end

    test "ignores disconnected voters" do
      game = create_game() |> add_voters(2)
      {:ok, game} = Game.cast_vote(game, "p1", "5")

      game = Game.update_participant(game, "p2", &Participant.set_connected(&1, false))

      assert Game.all_voters_voted?(game)
    end
  end

  describe "any_votes?/1" do
    test "returns true when at least one vote" do
      game = create_game() |> add_voters(2)
      {:ok, game} = Game.cast_vote(game, "p1", "5")

      assert Game.any_votes?(game)
    end

    test "returns false when no votes" do
      game = create_game() |> add_voters(2)

      refute Game.any_votes?(game)
    end
  end

  describe "calculate_statistics/1" do
    test "calculates average of numeric votes" do
      game = create_game() |> add_voters(3)
      {:ok, game} = Game.cast_vote(game, "p1", "5")
      {:ok, game} = Game.cast_vote(game, "p2", "8")
      {:ok, game} = Game.cast_vote(game, "p3", "5")

      {average, _distribution} = Game.calculate_statistics(game)

      assert average == 6.0
    end

    test "excludes non-numeric votes from average" do
      game = create_game() |> add_voters(3)
      {:ok, game} = Game.cast_vote(game, "p1", "5")
      {:ok, game} = Game.cast_vote(game, "p2", "?")
      {:ok, game} = Game.cast_vote(game, "p3", "5")

      {average, _distribution} = Game.calculate_statistics(game)

      assert average == 5.0
    end

    test "returns nil average when no numeric votes" do
      game = create_game() |> add_voters(2)
      {:ok, game} = Game.cast_vote(game, "p1", "?")
      {:ok, game} = Game.cast_vote(game, "p2", "coffee")

      {average, _distribution} = Game.calculate_statistics(game)

      assert average == nil
    end

    test "calculates vote distribution" do
      game = create_game() |> add_voters(4)
      {:ok, game} = Game.cast_vote(game, "p1", "5")
      {:ok, game} = Game.cast_vote(game, "p2", "5")
      {:ok, game} = Game.cast_vote(game, "p3", "8")
      {:ok, game} = Game.cast_vote(game, "p4", "?")

      {_average, distribution} = Game.calculate_statistics(game)

      assert distribution["5"] == 2
      assert distribution["8"] == 1
      assert distribution["?"] == 1
    end

    test "handles no votes" do
      game = create_game() |> add_voters(2)

      {average, distribution} = Game.calculate_statistics(game)

      assert average == nil
      assert distribution == %{}
    end
  end

  describe "empty?/1" do
    test "returns true for empty game" do
      game = create_game()
      assert Game.empty?(game)
    end

    test "returns false for game with participants" do
      game = create_game() |> add_voters(1)
      refute Game.empty?(game)
    end
  end

  describe "has_participant?/2" do
    test "returns true when participant exists" do
      game = create_game() |> add_voters(1)
      assert Game.has_participant?(game, "p1")
    end

    test "returns false when participant doesn't exist" do
      game = create_game() |> add_voters(1)
      refute Game.has_participant?(game, "nonexistent")
    end
  end
end
