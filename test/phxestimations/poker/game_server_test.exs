defmodule Phxestimations.Poker.GameServerTest do
  use ExUnit.Case, async: false

  alias Phxestimations.Poker.{GameServer, GameSupervisor}

  setup do
    # Ensure we start with a clean slate
    on_exit(fn ->
      # Stop any games that might still be running
      :ok
    end)

    :ok
  end

  defp start_game(name \\ "Test Game", deck_type \\ :fibonacci) do
    {:ok, game_id} = GameSupervisor.start_game(name, deck_type)
    game_id
  end

  describe "start_link/1 via GameSupervisor" do
    test "starts a game server" do
      game_id = start_game()

      assert GameServer.exists?(game_id)
    end

    test "can create multiple games" do
      game_id1 = start_game("Game 1")
      game_id2 = start_game("Game 2")

      assert GameServer.exists?(game_id1)
      assert GameServer.exists?(game_id2)
      assert game_id1 != game_id2
    end
  end

  describe "get_game/1" do
    test "returns game state" do
      game_id = start_game("Test Game", :fibonacci)

      {:ok, game} = GameServer.get_game(game_id)

      assert game.id == game_id
      assert game.name == "Test Game"
      assert game.deck_type == :fibonacci
      assert game.state == :voting
    end

    test "returns error for non-existent game" do
      assert {:error, :not_found} = GameServer.get_game("nonexistent")
    end
  end

  describe "join/4" do
    test "adds participant to game" do
      game_id = start_game()

      {:ok, game} = GameServer.join(game_id, "p1", "Alice", :voter)

      assert map_size(game.participants) == 1
      assert game.participants["p1"].name == "Alice"
      assert game.participants["p1"].role == :voter
    end

    test "can join as spectator" do
      game_id = start_game()

      {:ok, game} = GameServer.join(game_id, "p1", "Bob", :spectator)

      assert game.participants["p1"].role == :spectator
    end

    test "multiple participants can join" do
      game_id = start_game()

      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.join(game_id, "p2", "Bob", :voter)
      {:ok, game} = GameServer.join(game_id, "p3", "Charlie", :spectator)

      assert map_size(game.participants) == 3
    end
  end

  describe "leave/2" do
    test "removes participant from game" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.join(game_id, "p2", "Bob", :voter)

      {:ok, game} = GameServer.leave(game_id, "p1")

      assert map_size(game.participants) == 1
      refute Map.has_key?(game.participants, "p1")
    end
  end

  describe "vote/3" do
    test "records vote for participant" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)

      {:ok, game} = GameServer.vote(game_id, "p1", "5")

      assert game.participants["p1"].vote == "5"
    end

    test "allows changing vote" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.join(game_id, "p2", "Bob", :voter)
      GameServer.vote(game_id, "p1", "5")

      {:ok, game} = GameServer.vote(game_id, "p1", "8")

      assert game.participants["p1"].vote == "8"
    end

    test "returns error for invalid card" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)

      assert {:error, :invalid_card} = GameServer.vote(game_id, "p1", "invalid")
    end
  end

  describe "reveal/1" do
    test "changes game state to revealed" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.vote(game_id, "p1", "5")

      {:ok, game} = GameServer.reveal(game_id)

      assert game.state == :revealed
    end

    test "prevents voting after reveal" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.reveal(game_id)

      assert {:error, :already_revealed} = GameServer.vote(game_id, "p1", "5")
    end
  end

  describe "reset/1" do
    test "resets game to voting state" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.vote(game_id, "p1", "5")
      GameServer.reveal(game_id)

      {:ok, game} = GameServer.reset(game_id)

      assert game.state == :voting
      assert game.participants["p1"].vote == nil
    end
  end

  describe "set_story_name/2" do
    test "sets story name" do
      game_id = start_game()

      {:ok, game} = GameServer.set_story_name(game_id, "JIRA-123")

      assert game.story_name == "JIRA-123"
    end
  end

  describe "set_connected/3" do
    test "sets participant connection status" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)

      {:ok, game} = GameServer.set_connected(game_id, "p1", false)

      refute game.participants["p1"].connected
    end
  end

  describe "exists?/1" do
    test "returns true for existing game" do
      game_id = start_game()
      assert GameServer.exists?(game_id)
    end

    test "returns false for non-existent game" do
      refute GameServer.exists?("nonexistent")
    end
  end

  describe "PubSub broadcasts" do
    test "broadcasts participant_joined event" do
      game_id = start_game()
      Phoenix.PubSub.subscribe(Phxestimations.PubSub, "game:#{game_id}")

      GameServer.join(game_id, "p1", "Alice", :voter)

      assert_receive {:participant_joined, participant}
      assert participant.name == "Alice"
    end

    test "broadcasts participant_left event" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      Phoenix.PubSub.subscribe(Phxestimations.PubSub, "game:#{game_id}")

      GameServer.leave(game_id, "p1")

      assert_receive {:participant_left, "p1"}
    end

    test "broadcasts vote_cast event" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      Phoenix.PubSub.subscribe(Phxestimations.PubSub, "game:#{game_id}")

      GameServer.vote(game_id, "p1", "5")

      assert_receive {:vote_cast, "p1"}
    end

    test "broadcasts votes_revealed event" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.vote(game_id, "p1", "5")
      Phoenix.PubSub.subscribe(Phxestimations.PubSub, "game:#{game_id}")

      GameServer.reveal(game_id)

      assert_receive {:votes_revealed, game}
      assert game.state == :revealed
    end

    test "broadcasts round_reset event" do
      game_id = start_game()
      GameServer.join(game_id, "p1", "Alice", :voter)
      GameServer.vote(game_id, "p1", "5")
      GameServer.reveal(game_id)
      Phoenix.PubSub.subscribe(Phxestimations.PubSub, "game:#{game_id}")

      GameServer.reset(game_id)

      assert_receive {:round_reset, game}
      assert game.state == :voting
    end
  end
end
