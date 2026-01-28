defmodule Mix.Tasks.SmokeTest do
  @moduledoc """
  Quick verification of core Planning Poker flows without ExUnit.

  Runs through game lifecycle, voting, spectator mode, and deck types
  using the Poker API directly. Reports PASS/FAIL per test case.

  ## Usage

      mix smoke_test
  """

  use Mix.Task

  alias Phxestimations.Poker
  alias Phxestimations.Poker.Game

  @shortdoc "Run smoke tests for core game flows"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    results = [
      run_test("Fibonacci game lifecycle", &test_fibonacci_lifecycle/0),
      run_test("T-shirt game lifecycle", &test_tshirt_lifecycle/0),
      run_test("Vote change before reveal", &test_vote_change/0),
      run_test("Spectator mode", &test_spectator_mode/0),
      run_test("Story name set/clear", &test_story_name/0),
      run_test("Multiple rounds", &test_multiple_rounds/0),
      run_test("T-shirt no average", &test_tshirt_no_average/0),
      run_test("Empty reveal", &test_empty_reveal/0)
    ]

    passed = Enum.count(results, &(&1 == :pass))
    failed = Enum.count(results, &(&1 == :fail))
    total = length(results)

    IO.puts("\n#{String.duplicate("=", 50)}")
    IO.puts("Results: #{passed}/#{total} passed, #{failed} failed")
    IO.puts(String.duplicate("=", 50))

    if failed > 0 do
      System.halt(1)
    end
  end

  defp run_test(name, test_fn) do
    try do
      test_fn.()
      IO.puts("  PASS  #{name}")
      :pass
    rescue
      e ->
        IO.puts("  FAIL  #{name}")
        IO.puts("        #{Exception.message(e)}")
        :fail
    end
  end

  defp test_fibonacci_lifecycle do
    {:ok, game_id} = Poker.create_game("Smoke Fib", :fibonacci)
    pid1 = join_participant(game_id, "Alice", :voter)
    pid2 = join_participant(game_id, "Bob", :voter)

    {:ok, _} = Poker.cast_vote(game_id, pid1, "5")
    {:ok, _} = Poker.cast_vote(game_id, pid2, "8")

    {:ok, game} = Poker.reveal_votes(game_id)
    assert!(game.state == :revealed, "Expected revealed state")

    {average, _dist} = Game.calculate_statistics(game)
    assert!(average == 6.5, "Expected average 6.5, got #{inspect(average)}")

    {:ok, game} = Poker.reset_round(game_id)
    assert!(game.state == :voting, "Expected voting state after reset")

    voters = Enum.filter(game.participants, fn {_id, p} -> p.role == :voter end)
    assert!(Enum.all?(voters, fn {_id, p} -> p.vote == nil end), "Expected votes cleared")
  end

  defp test_tshirt_lifecycle do
    {:ok, game_id} = Poker.create_game("Smoke TShirt", :tshirt)
    pid1 = join_participant(game_id, "Alice", :voter)
    pid2 = join_participant(game_id, "Bob", :voter)

    {:ok, _} = Poker.cast_vote(game_id, pid1, "M")
    {:ok, _} = Poker.cast_vote(game_id, pid2, "L")

    {:ok, game} = Poker.reveal_votes(game_id)
    assert!(game.state == :revealed, "Expected revealed state")

    {:ok, game} = Poker.reset_round(game_id)
    assert!(game.state == :voting, "Expected voting state after reset")
  end

  defp test_vote_change do
    {:ok, game_id} = Poker.create_game("Smoke Change", :fibonacci)
    pid1 = join_participant(game_id, "Alice", :voter)

    {:ok, _} = Poker.cast_vote(game_id, pid1, "5")
    {:ok, game} = Poker.cast_vote(game_id, pid1, "8")

    participant = game.participants[pid1]
    assert!(participant.vote == "8", "Expected vote to be 8, got #{inspect(participant.vote)}")
  end

  defp test_spectator_mode do
    {:ok, game_id} = Poker.create_game("Smoke Spectator", :fibonacci)
    pid1 = join_participant(game_id, "Alice", :voter)
    _spec = join_participant(game_id, "Observer", :spectator)

    {:ok, _} = Poker.cast_vote(game_id, pid1, "5")

    {:ok, game} = Poker.get_game(game_id)
    voters = Enum.filter(game.participants, fn {_id, p} -> p.role == :voter end)
    spectators = Enum.filter(game.participants, fn {_id, p} -> p.role == :spectator end)

    assert!(length(voters) == 1, "Expected 1 voter")
    assert!(length(spectators) == 1, "Expected 1 spectator")
  end

  defp test_story_name do
    {:ok, game_id} = Poker.create_game("Smoke Story", :fibonacci)
    _pid = join_participant(game_id, "Alice", :voter)

    {:ok, game} = Poker.set_story_name(game_id, "PROJ-101")
    assert!(game.story_name == "PROJ-101", "Expected story name to be set")

    {:ok, game} = Poker.reset_round(game_id)
    assert!(game.story_name == nil, "Expected story name cleared after reset")
  end

  defp test_multiple_rounds do
    {:ok, game_id} = Poker.create_game("Smoke Rounds", :fibonacci)
    pid1 = join_participant(game_id, "Alice", :voter)
    pid2 = join_participant(game_id, "Bob", :voter)

    # Round 1
    {:ok, _} = Poker.cast_vote(game_id, pid1, "3")
    {:ok, _} = Poker.cast_vote(game_id, pid2, "5")
    {:ok, _} = Poker.reveal_votes(game_id)
    {:ok, _} = Poker.reset_round(game_id)

    # Round 2
    {:ok, _} = Poker.cast_vote(game_id, pid1, "8")
    {:ok, _} = Poker.cast_vote(game_id, pid2, "8")
    {:ok, game} = Poker.reveal_votes(game_id)

    {average, _} = Game.calculate_statistics(game)
    assert!(average == 8.0, "Expected average 8.0 in round 2, got #{inspect(average)}")
  end

  defp test_tshirt_no_average do
    {:ok, game_id} = Poker.create_game("Smoke TShirt Avg", :tshirt)
    pid1 = join_participant(game_id, "Alice", :voter)

    {:ok, _} = Poker.cast_vote(game_id, pid1, "M")
    {:ok, game} = Poker.reveal_votes(game_id)

    {average, _} = Game.calculate_statistics(game)
    assert!(average == nil, "Expected nil average for t-shirt, got #{inspect(average)}")
  end

  defp test_empty_reveal do
    {:ok, game_id} = Poker.create_game("Smoke Empty", :fibonacci)
    _pid = join_participant(game_id, "Alice", :voter)

    {:ok, game} = Poker.reveal_votes(game_id)
    assert!(game.state == :revealed, "Expected revealed state")

    {average, _} = Game.calculate_statistics(game)
    assert!(average == nil, "Expected nil average with no votes")
  end

  defp join_participant(game_id, name, role) do
    participant_id = Poker.generate_participant_id()
    {:ok, _game} = Poker.join_game(game_id, participant_id, name, role)
    participant_id
  end

  defp assert!(true, _message), do: :ok
  defp assert!(false, message), do: raise(message)
end
