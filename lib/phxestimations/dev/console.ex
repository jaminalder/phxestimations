defmodule Phxestimations.Dev.Console do
  @moduledoc """
  IEx helper module for AI agent development and interactive debugging.

  Provides quick actions, state inspection, and predefined scenarios for
  working with Planning Poker games from the console.

  ## Usage

      iex -S mix phx.server
      alias Phxestimations.Dev.Console, as: C
      C.demo()
      C.list_games()

  ## Quick Start

      C.create("Sprint 42", :fibonacci)    # Create a game
      {gid, pids} = C.quick_game(3)        # Create game + 3 voters
      C.vote(gid, hd(pids), "5")           # Cast a vote
      C.reveal(gid)                        # Reveal votes
      C.reset(gid)                         # New round
  """

  alias Phxestimations.Poker
  alias Phxestimations.Poker.Game

  # ============================================================================
  # Quick Actions
  # ============================================================================

  @doc """
  Creates a new game. Prints game_id and join URL.

  ## Examples

      C.create("Sprint 42", :fibonacci)
      C.create("Sizing", :tshirt)
      C.create()  # auto-generated name, fibonacci deck
  """
  def create(name \\ nil, deck_type \\ :fibonacci) do
    {:ok, game_id} = Poker.create_game(name, deck_type)
    {:ok, game} = Poker.get_game(game_id)

    IO.puts("""
    Game created!
      ID:   #{game_id}
      Name: #{game.name}
      Deck: #{Poker.deck_display_name(deck_type)}
      URL:  /games/#{game_id}/join
    """)

    game_id
  end

  @doc """
  Joins a game as a participant. Returns the participant_id.

  ## Examples

      pid = C.join(game_id, "Alice")
      pid = C.join(game_id, "Bob", :spectator)
  """
  def join(game_id, name, role \\ :voter) do
    participant_id = Poker.generate_participant_id()
    {:ok, _game} = Poker.join_game(game_id, participant_id, name, role)

    short_pid = String.slice(participant_id, 0, 8)
    IO.puts("#{name} joined as #{role} (pid: #{short_pid}...)")

    participant_id
  end

  @doc """
  Casts a vote for a participant.

  ## Examples

      C.vote(game_id, participant_id, "5")
  """
  def vote(game_id, participant_id, card) do
    case Poker.cast_vote(game_id, participant_id, card) do
      {:ok, _game} ->
        IO.puts("Vote cast: #{card}")
        :ok

      {:error, reason} ->
        IO.puts("Vote failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Reveals votes and prints results table.

  ## Examples

      C.reveal(game_id)
  """
  def reveal(game_id) do
    {:ok, game} = Poker.reveal_votes(game_id)
    {average, _distribution} = Game.calculate_statistics(game)

    IO.puts("\n--- Votes Revealed ---")

    game.participants
    |> Enum.filter(fn {_id, p} -> p.role == :voter end)
    |> Enum.sort_by(fn {_id, p} -> p.name end)
    |> Enum.each(fn {_id, p} ->
      vote_str = p.vote || "-"
      IO.puts("  #{String.pad_trailing(p.name, 15)} #{vote_str}")
    end)

    if average do
      IO.puts("  #{String.pad_trailing("Average", 15)} #{Float.round(average, 1)}")
    end

    IO.puts("----------------------\n")
    :ok
  end

  @doc """
  Resets the round for a new voting cycle.
  """
  def reset(game_id) do
    {:ok, _game} = Poker.reset_round(game_id)
    IO.puts("Round reset. Ready for new votes.")
    :ok
  end

  @doc """
  Sets the story name for the current round.
  """
  def story(game_id, name) do
    {:ok, _game} = Poker.set_story_name(game_id, name)
    IO.puts("Story set: #{name}")
    :ok
  end

  # ============================================================================
  # State Inspection
  # ============================================================================

  @doc """
  Pretty-prints the full game state.
  """
  def inspect_game(game_id) do
    case Poker.get_game(game_id) do
      {:ok, game} ->
        {average, distribution} = Game.calculate_statistics(game)

        IO.puts("""

        === Game: #{game.name} (#{game.id}) ===
        State:      #{game.state}
        Deck:       #{Poker.deck_display_name(game.deck_type)}
        Story:      #{game.story_name || "(none)"}
        Created:    #{game.created_at}
        Participants: #{map_size(game.participants)}
        """)

        participants(game_id)

        if game.state == :revealed do
          IO.puts("  Average: #{if average, do: Float.round(average, 1), else: "N/A"}")

          IO.puts("  Distribution:")

          Enum.each(distribution, fn {card, count} ->
            bar = String.duplicate("#", count)
            IO.puts("    #{String.pad_trailing(card, 6)} #{bar} (#{count})")
          end)

          IO.puts("")
        end

        :ok

      {:error, :not_found} ->
        IO.puts("Game not found: #{game_id}")
        {:error, :not_found}
    end
  end

  @doc """
  Lists participants with role, connection status, and vote status.
  """
  def participants(game_id) do
    case Poker.get_game(game_id) do
      {:ok, game} ->
        IO.puts("  Participants:")

        game.participants
        |> Enum.sort_by(fn {_id, p} -> {p.role, p.name} end)
        |> Enum.each(fn {_id, p} ->
          conn_status = if p.connected, do: "online", else: "offline"
          vote_status = if p.vote, do: "voted", else: "pending"
          role_str = if p.role == :spectator, do: "spectator", else: "voter"

          IO.puts(
            "    #{String.pad_trailing(p.name, 15)} #{String.pad_trailing(role_str, 12)} #{String.pad_trailing(conn_status, 10)} #{vote_status}"
          )
        end)

        IO.puts("")
        :ok

      {:error, :not_found} ->
        IO.puts("Game not found: #{game_id}")
        {:error, :not_found}
    end
  end

  @doc """
  Shows votes if revealed, or vote count if voting.
  """
  def votes(game_id) do
    case Poker.get_game(game_id) do
      {:ok, %{state: :revealed} = game} ->
        IO.puts("Votes (revealed):")

        game.participants
        |> Enum.filter(fn {_id, p} -> p.role == :voter end)
        |> Enum.sort_by(fn {_id, p} -> p.name end)
        |> Enum.each(fn {_id, p} ->
          IO.puts("  #{String.pad_trailing(p.name, 15)} #{p.vote || "-"}")
        end)

        :ok

      {:ok, game} ->
        voters = Enum.filter(game.participants, fn {_id, p} -> p.role == :voter end)
        voted = Enum.count(voters, fn {_id, p} -> p.vote != nil end)
        total = length(voters)
        IO.puts("Voting in progress: #{voted}/#{total} voted")
        :ok

      {:error, :not_found} ->
        IO.puts("Game not found: #{game_id}")
        {:error, :not_found}
    end
  end

  @doc """
  Lists all active games from the Registry.
  """
  def list_games do
    games =
      Registry.select(Phxestimations.Poker.GameRegistry, [
        {{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}
      ])

    if games == [] do
      IO.puts("No active games.")
    else
      IO.puts("\nActive games:")

      IO.puts(
        "  #{String.pad_trailing("ID", 10)} #{String.pad_trailing("Name", 30)} Participants"
      )

      IO.puts("  #{String.duplicate("-", 60)}")

      Enum.each(games, fn {game_id, _pid} ->
        case Poker.get_game(game_id) do
          {:ok, game} ->
            IO.puts(
              "  #{String.pad_trailing(game_id, 10)} #{String.pad_trailing(game.name, 30)} #{map_size(game.participants)}"
            )

          _ ->
            nil
        end
      end)

      IO.puts("")
    end

    :ok
  end

  # ============================================================================
  # Scenarios
  # ============================================================================

  @doc """
  Creates a game and joins N voters. Returns `{game_id, participant_ids}`.

  ## Options

    * `:name` - game name (default: "Quick Game")
    * `:deck` - deck type (default: :fibonacci)
    * `:names` - participant names

  ## Examples

      {gid, pids} = C.quick_game(3)
      {gid, pids} = C.quick_game(2, names: ["Dev1", "Dev2"])
  """
  def quick_game(n, opts \\ []) do
    name = Keyword.get(opts, :name, "Quick Game")
    deck = Keyword.get(opts, :deck, :fibonacci)
    names = Keyword.get(opts, :names, default_names(n))

    game_id = create(name, deck)

    pids =
      names
      |> Enum.take(n)
      |> Enum.map(fn pname -> join(game_id, pname) end)

    IO.puts("\nQuick game ready! #{n} voters joined.")
    {game_id, pids}
  end

  @doc """
  Scenario: All voters agree on "5" (consensus).
  """
  def scenario_consensus do
    {game_id, pids} = quick_game(4, name: "Consensus Demo")

    Enum.each(pids, fn pid -> vote(game_id, pid, "5") end)
    reveal(game_id)

    game_id
  end

  @doc """
  Scenario: Wide spread of votes (1, 5, 13, 34).
  """
  def scenario_disagreement do
    {game_id, pids} = quick_game(4, name: "Disagreement Demo")

    votes = ["1", "5", "13", "34"]

    Enum.zip(pids, votes)
    |> Enum.each(fn {pid, card} -> vote(game_id, pid, card) end)

    reveal(game_id)

    game_id
  end

  @doc """
  Scenario: T-shirt deck game with votes.
  """
  def scenario_tshirt do
    {game_id, pids} = quick_game(3, name: "T-Shirt Demo", deck: :tshirt)

    votes = ["S", "M", "L"]

    Enum.zip(pids, votes)
    |> Enum.each(fn {pid, card} -> vote(game_id, pid, card) end)

    reveal(game_id)

    game_id
  end

  @doc """
  Full demo: 2-round lifecycle with story names.
  """
  def demo do
    IO.puts("\n=== Planning Poker Demo ===\n")

    {game_id, pids} = quick_game(3, name: "Demo Game")

    # Round 1
    story(game_id, "PROJ-101: User login")

    votes_r1 = ["5", "8", "5"]

    Enum.zip(pids, votes_r1)
    |> Enum.each(fn {pid, card} -> vote(game_id, pid, card) end)

    reveal(game_id)

    IO.puts("Starting round 2...\n")
    reset(game_id)

    # Round 2
    story(game_id, "PROJ-102: Password reset")

    votes_r2 = ["3", "5", "3"]

    Enum.zip(pids, votes_r2)
    |> Enum.each(fn {pid, card} -> vote(game_id, pid, card) end)

    reveal(game_id)

    IO.puts("=== Demo Complete ===\n")
    inspect_game(game_id)

    game_id
  end

  # ============================================================================
  # Private
  # ============================================================================

  defp default_names(n) do
    all = ~w(Alice Bob Charlie Diana Eve Frank Grace Henry Ivy Jack)
    Enum.take(all, n)
  end
end
