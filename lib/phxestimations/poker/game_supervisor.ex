defmodule Phxestimations.Poker.GameSupervisor do
  @moduledoc """
  DynamicSupervisor for managing Planning Poker game processes.

  Each game runs as a separate child process under this supervisor,
  allowing games to be created and stopped dynamically.
  """

  use DynamicSupervisor

  alias Phxestimations.Poker.GameServer

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new game with the given name and deck type.
  Returns `{:ok, game_id}` on success.
  """
  def start_game(name, deck_type) do
    game_id = generate_game_id()

    case DynamicSupervisor.start_child(__MODULE__, {GameServer, {game_id, name, deck_type}}) do
      {:ok, _pid} -> {:ok, game_id}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Stops a game by its ID.
  """
  def stop_game(game_id) do
    case GenServer.whereis(GameServer.via_tuple(game_id)) do
      nil ->
        {:error, :not_found}

      pid ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  @doc """
  Returns the count of active games.
  """
  def game_count do
    DynamicSupervisor.count_children(__MODULE__)[:active] || 0
  end

  # Generate a unique game ID (6 character alphanumeric)
  defp generate_game_id do
    :crypto.strong_rand_bytes(4)
    |> Base.url_encode64(padding: false)
    |> String.slice(0, 6)
    |> String.downcase()
  end
end
