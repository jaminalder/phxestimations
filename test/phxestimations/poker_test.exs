defmodule Phxestimations.PokerTest do
  use ExUnit.Case, async: false

  alias Phxestimations.Poker

  describe "create_game/2" do
    test "creates a game with given name and deck type" do
      {:ok, game_id} = Poker.create_game("Sprint Planning", :fibonacci)

      assert is_binary(game_id)
      assert Poker.game_exists?(game_id)

      {:ok, game} = Poker.get_game(game_id)
      assert game.name == "Sprint Planning"
      assert game.deck_type == :fibonacci
    end

    test "creates a game with tshirt deck" do
      {:ok, game_id} = Poker.create_game("Sizing", :tshirt)

      {:ok, game} = Poker.get_game(game_id)
      assert game.deck_type == :tshirt
    end

    test "auto-generates name when nil" do
      {:ok, game_id} = Poker.create_game(nil, :fibonacci)

      {:ok, game} = Poker.get_game(game_id)
      assert is_binary(game.name)
      assert String.length(game.name) > 0
    end

    test "auto-generates name when empty string" do
      {:ok, game_id} = Poker.create_game("", :fibonacci)

      {:ok, game} = Poker.get_game(game_id)
      assert is_binary(game.name)
      assert String.length(game.name) > 0
    end

    test "auto-generates name when whitespace only" do
      {:ok, game_id} = Poker.create_game("   ", :fibonacci)

      {:ok, game} = Poker.get_game(game_id)
      assert String.trim(game.name) != ""
    end
  end

  describe "get_game/1" do
    test "returns game state" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)

      {:ok, game} = Poker.get_game(game_id)

      assert game.id == game_id
      assert game.name == "Test"
    end

    test "returns error for non-existent game" do
      assert {:error, :not_found} = Poker.get_game("nonexistent")
    end
  end

  describe "get_game!/1" do
    test "returns game state" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)

      game = Poker.get_game!(game_id)

      assert game.id == game_id
    end

    test "raises for non-existent game" do
      assert_raise RuntimeError, fn ->
        Poker.get_game!("nonexistent")
      end
    end
  end

  describe "game_exists?/1" do
    test "returns true for existing game" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      assert Poker.game_exists?(game_id)
    end

    test "returns false for non-existent game" do
      refute Poker.game_exists?("nonexistent")
    end
  end

  describe "join_game/4" do
    test "joins game as voter" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      participant_id = Poker.generate_participant_id()

      {:ok, game} = Poker.join_game(game_id, participant_id, "Alice", :voter)

      assert map_size(game.participants) == 1
      assert game.participants[participant_id].name == "Alice"
      assert game.participants[participant_id].role == :voter
    end

    test "joins game as spectator" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      participant_id = Poker.generate_participant_id()

      {:ok, game} = Poker.join_game(game_id, participant_id, "Bob", :spectator)

      assert game.participants[participant_id].role == :spectator
    end
  end

  describe "leave_game/2" do
    test "removes participant from game" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      participant_id = Poker.generate_participant_id()
      Poker.join_game(game_id, participant_id, "Alice", :voter)

      {:ok, game} = Poker.leave_game(game_id, participant_id)

      assert map_size(game.participants) == 0
    end
  end

  describe "cast_vote/3" do
    test "records vote" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      participant_id = Poker.generate_participant_id()
      Poker.join_game(game_id, participant_id, "Alice", :voter)

      {:ok, game} = Poker.cast_vote(game_id, participant_id, "5")

      assert game.participants[participant_id].vote == "5"
    end

    test "returns error for invalid card" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      participant_id = Poker.generate_participant_id()
      Poker.join_game(game_id, participant_id, "Alice", :voter)

      assert {:error, :invalid_card} = Poker.cast_vote(game_id, participant_id, "invalid")
    end
  end

  describe "reveal_votes/1" do
    test "reveals votes" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      participant_id = Poker.generate_participant_id()
      Poker.join_game(game_id, participant_id, "Alice", :voter)
      Poker.cast_vote(game_id, participant_id, "5")

      {:ok, game} = Poker.reveal_votes(game_id)

      assert game.state == :revealed
    end
  end

  describe "reset_round/1" do
    test "resets game for new round" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      participant_id = Poker.generate_participant_id()
      Poker.join_game(game_id, participant_id, "Alice", :voter)
      Poker.cast_vote(game_id, participant_id, "5")
      Poker.reveal_votes(game_id)

      {:ok, game} = Poker.reset_round(game_id)

      assert game.state == :voting
      assert game.participants[participant_id].vote == nil
    end
  end

  describe "set_story_name/2" do
    test "sets story name" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)

      {:ok, game} = Poker.set_story_name(game_id, "JIRA-123")

      assert game.story_name == "JIRA-123"
    end
  end

  describe "subscribe/1 and unsubscribe/1" do
    test "receives events after subscribing" do
      {:ok, game_id} = Poker.create_game("Test", :fibonacci)
      Poker.subscribe(game_id)

      participant_id = Poker.generate_participant_id()
      Poker.join_game(game_id, participant_id, "Alice", :voter)

      assert_receive {:participant_joined, _participant}
    end
  end

  describe "deck_types/0" do
    test "returns available deck types" do
      types = Poker.deck_types()

      assert :fibonacci in types
      assert :tshirt in types
    end
  end

  describe "deck_cards/1" do
    test "returns fibonacci cards" do
      cards = Poker.deck_cards(:fibonacci)

      assert "5" in cards
      assert "13" in cards
      assert "?" in cards
    end

    test "returns tshirt cards" do
      cards = Poker.deck_cards(:tshirt)

      assert "S" in cards
      assert "XL" in cards
      assert "?" in cards
    end
  end

  describe "deck_display_name/1" do
    test "returns display names" do
      assert Poker.deck_display_name(:fibonacci) == "Fibonacci"
      assert Poker.deck_display_name(:tshirt) == "T-Shirt Sizes"
    end
  end

  describe "generate_participant_id/0" do
    test "generates unique IDs" do
      id1 = Poker.generate_participant_id()
      id2 = Poker.generate_participant_id()

      assert is_binary(id1)
      assert is_binary(id2)
      assert id1 != id2
    end
  end

  describe "topic/1" do
    test "returns correct topic format" do
      assert Poker.topic("abc123") == "game:abc123"
    end
  end
end
