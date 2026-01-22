defmodule Phxestimations.Poker.GameServer do
  @moduledoc """
  GenServer that manages the state of a single Planning Poker game.

  Each game runs in its own process, allowing for isolated state management
  and automatic cleanup when the game is no longer in use.
  """

  use GenServer

  alias Phxestimations.Poker.{Game, Participant}

  @timeout_check_interval :timer.minutes(1)
  @empty_game_timeout :timer.minutes(5)

  # Client API

  @doc """
  Starts a new game server.
  """
  def start_link({game_id, name, deck_type}) do
    GenServer.start_link(__MODULE__, {game_id, name, deck_type}, name: via_tuple(game_id))
  end

  @doc """
  Returns the via tuple for process registration.
  """
  def via_tuple(game_id) do
    {:via, Registry, {Phxestimations.Poker.GameRegistry, game_id}}
  end

  @doc """
  Gets the current game state.
  """
  def get_game(game_id) do
    case GenServer.whereis(via_tuple(game_id)) do
      nil -> {:error, :not_found}
      pid -> GenServer.call(pid, :get_game)
    end
  end

  @doc """
  Adds a participant to the game.
  """
  def join(game_id, participant_id, name, role) do
    GenServer.call(via_tuple(game_id), {:join, participant_id, name, role})
  end

  @doc """
  Removes a participant from the game.
  """
  def leave(game_id, participant_id) do
    GenServer.call(via_tuple(game_id), {:leave, participant_id})
  end

  @doc """
  Casts a vote for a participant.
  """
  def vote(game_id, participant_id, card) do
    GenServer.call(via_tuple(game_id), {:vote, participant_id, card})
  end

  @doc """
  Reveals all votes.
  """
  def reveal(game_id) do
    GenServer.call(via_tuple(game_id), :reveal)
  end

  @doc """
  Resets the game for a new voting round.
  """
  def reset(game_id) do
    GenServer.call(via_tuple(game_id), :reset)
  end

  @doc """
  Sets the story name for the current round.
  """
  def set_story_name(game_id, story_name) do
    GenServer.call(via_tuple(game_id), {:set_story_name, story_name})
  end

  @doc """
  Sets a participant's connection status.
  """
  def set_connected(game_id, participant_id, connected) do
    GenServer.call(via_tuple(game_id), {:set_connected, participant_id, connected})
  end

  @doc """
  Checks if a game process exists.
  """
  def exists?(game_id) do
    GenServer.whereis(via_tuple(game_id)) != nil
  end

  # Server Callbacks

  @impl true
  def init({game_id, name, deck_type}) do
    game = Game.new(game_id, name, deck_type)
    schedule_timeout_check()
    {:ok, %{game: game, last_activity: System.monotonic_time(:millisecond)}}
  end

  @impl true
  def handle_call(:get_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl true
  def handle_call({:join, participant_id, name, role}, _from, state) do
    participant = Participant.new(participant_id, name, role)
    game = Game.add_participant(state.game, participant)
    state = %{state | game: game, last_activity: now()}

    broadcast(game, {:participant_joined, participant})
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_call({:leave, participant_id}, _from, state) do
    game = Game.remove_participant(state.game, participant_id)
    state = %{state | game: game, last_activity: now()}

    broadcast(game, {:participant_left, participant_id})
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_call({:vote, participant_id, card}, _from, state) do
    case Game.cast_vote(state.game, participant_id, card) do
      {:ok, game} ->
        state = %{state | game: game, last_activity: now()}
        broadcast(game, {:vote_cast, participant_id})
        {:reply, {:ok, game}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:reveal, _from, state) do
    game = Game.reveal_votes(state.game)
    state = %{state | game: game, last_activity: now()}

    broadcast(game, {:votes_revealed, game})
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    game = Game.reset_round(state.game)
    state = %{state | game: game, last_activity: now()}

    broadcast(game, {:round_reset, game})
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_call({:set_story_name, story_name}, _from, state) do
    game = Game.set_story_name(state.game, story_name)
    state = %{state | game: game, last_activity: now()}

    broadcast(game, {:story_name_changed, story_name})
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_call({:set_connected, participant_id, connected}, _from, state) do
    game =
      Game.update_participant(
        state.game,
        participant_id,
        &Participant.set_connected(&1, connected)
      )

    state = %{state | game: game, last_activity: now()}

    event =
      if connected,
        do: {:participant_reconnected, participant_id},
        else: {:participant_disconnected, participant_id}

    broadcast(game, event)
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_info(:check_timeout, state) do
    if should_shutdown?(state) do
      {:stop, :normal, state}
    else
      schedule_timeout_check()
      {:noreply, state}
    end
  end

  # Private Functions

  defp broadcast(game, event) do
    Phoenix.PubSub.broadcast(
      Phxestimations.PubSub,
      topic(game.id),
      event
    )
  end

  defp topic(game_id), do: "game:#{game_id}"

  defp schedule_timeout_check do
    Process.send_after(self(), :check_timeout, @timeout_check_interval)
  end

  defp now, do: System.monotonic_time(:millisecond)

  defp should_shutdown?(state) do
    game_empty? = Game.empty?(state.game)
    time_since_activity = now() - state.last_activity
    game_empty? and time_since_activity > @empty_game_timeout
  end
end
