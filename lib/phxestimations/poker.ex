defmodule Phxestimations.Poker do
  @moduledoc """
  The Poker context - public API for Planning Poker functionality.

  This module provides a clean interface for all poker-related operations,
  abstracting away the implementation details of game state management.
  """

  alias Phxestimations.Poker.{Avatar, Deck, Game, GameServer, GameSupervisor}

  @pubsub Phxestimations.PubSub

  # ============================================================================
  # Game Lifecycle
  # ============================================================================

  @doc """
  Creates a new game with the given name and deck type.

  If name is nil or empty, a random name will be generated.

  ## Examples

      {:ok, game_id} = Poker.create_game("Sprint Planning", :fibonacci)
      {:ok, game_id} = Poker.create_game(nil, :tshirt) # Auto-generates name
  """
  @spec create_game(String.t() | nil, Deck.deck_type()) :: {:ok, String.t()} | {:error, term()}
  def create_game(name \\ nil, deck_type \\ :fibonacci) do
    game_name = if blank?(name), do: generate_game_name(), else: name
    GameSupervisor.start_game(game_name, deck_type)
  end

  @doc """
  Gets the current state of a game.
  """
  @spec get_game(String.t()) :: {:ok, Game.t()} | {:error, :not_found}
  def get_game(game_id) do
    GameServer.get_game(game_id)
  end

  @doc """
  Gets the current state of a game, raising if not found.
  """
  @spec get_game!(String.t()) :: Game.t()
  def get_game!(game_id) do
    case get_game(game_id) do
      {:ok, game} -> game
      {:error, :not_found} -> raise "Game not found: #{game_id}"
    end
  end

  @doc """
  Checks if a game exists.
  """
  @spec game_exists?(String.t()) :: boolean()
  def game_exists?(game_id) do
    GameServer.exists?(game_id)
  end

  # ============================================================================
  # Participation
  # ============================================================================

  @doc """
  Joins a game as a participant.

  ## Parameters
    - game_id: The game to join
    - participant_id: Unique ID for this participant (usually from session)
    - name: Display name
    - role: `:voter` or `:spectator`
    - avatar_id: Optional avatar ID (1-7)

  ## Examples

      {:ok, game} = Poker.join_game("abc123", "user-uuid", "Alice", :voter)
      {:ok, game} = Poker.join_game("abc123", "user-uuid", "Alice", :voter, 3)
  """
  @spec join_game(String.t(), String.t(), String.t(), :voter | :spectator, pos_integer() | nil) ::
          {:ok, Game.t()} | {:error, term()}
  def join_game(game_id, participant_id, name, role, avatar_id \\ nil) do
    GameServer.join(game_id, participant_id, name, role, avatar_id)
  end

  @doc """
  Returns available avatar IDs for a game (not currently in use by other participants).
  """
  @spec available_avatars(String.t()) :: {:ok, [pos_integer()]} | {:error, :not_found}
  def available_avatars(game_id) do
    GameServer.available_avatars(game_id)
  end

  @doc """
  Leaves a game.
  """
  @spec leave_game(String.t(), String.t()) :: {:ok, Game.t()} | {:error, term()}
  def leave_game(game_id, participant_id) do
    GameServer.leave(game_id, participant_id)
  end

  @doc """
  Sets a participant's connection status.
  """
  @spec set_participant_connected(String.t(), String.t(), boolean()) ::
          {:ok, Game.t()} | {:error, term()}
  def set_participant_connected(game_id, participant_id, connected) do
    GameServer.set_connected(game_id, participant_id, connected)
  end

  # ============================================================================
  # Voting
  # ============================================================================

  @doc """
  Casts a vote for a participant.
  """
  @spec cast_vote(String.t(), String.t(), String.t()) ::
          {:ok, Game.t()} | {:error, :invalid_card | :already_revealed}
  def cast_vote(game_id, participant_id, card) do
    GameServer.vote(game_id, participant_id, card)
  end

  @doc """
  Reveals all votes in a game.
  """
  @spec reveal_votes(String.t()) :: {:ok, Game.t()}
  def reveal_votes(game_id) do
    GameServer.reveal(game_id)
  end

  @doc """
  Resets the game for a new voting round.
  """
  @spec reset_round(String.t()) :: {:ok, Game.t()}
  def reset_round(game_id) do
    GameServer.reset(game_id)
  end

  @doc """
  Sets the story name for the current round.
  """
  @spec set_story_name(String.t(), String.t() | nil) :: {:ok, Game.t()}
  def set_story_name(game_id, story_name) do
    GameServer.set_story_name(game_id, story_name)
  end

  # ============================================================================
  # PubSub
  # ============================================================================

  @doc """
  Subscribes to game updates.

  Events published:
    - `{:participant_joined, participant}`
    - `{:participant_left, participant_id}`
    - `{:participant_connected, participant_id}`
    - `{:participant_disconnected, participant_id}`
    - `{:vote_cast, participant_id}`
    - `{:votes_revealed, game}`
    - `{:round_reset, game}`
    - `{:story_name_changed, story_name}`
  """
  @spec subscribe(String.t()) :: :ok | {:error, term()}
  def subscribe(game_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(game_id))
  end

  @doc """
  Unsubscribes from game updates.
  """
  @spec unsubscribe(String.t()) :: :ok
  def unsubscribe(game_id) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(game_id))
  end

  @doc """
  Returns the PubSub topic for a game.
  """
  @spec topic(String.t()) :: String.t()
  def topic(game_id), do: "game:#{game_id}"

  # ============================================================================
  # Deck Utilities
  # ============================================================================

  @doc """
  Returns available deck types.
  """
  @spec deck_types() :: [Deck.deck_type()]
  defdelegate deck_types, to: Deck, as: :types

  @doc """
  Returns cards for a deck type.
  """
  @spec deck_cards(Deck.deck_type()) :: [String.t()]
  defdelegate deck_cards(deck_type), to: Deck, as: :cards

  @doc """
  Returns display name for a deck type.
  """
  @spec deck_display_name(Deck.deck_type()) :: String.t()
  defdelegate deck_display_name(deck_type), to: Deck, as: :display_name

  # ============================================================================
  # Avatar Utilities
  # ============================================================================

  @doc """
  Returns all avatar IDs.
  """
  @spec avatar_ids() :: [pos_integer()]
  defdelegate avatar_ids, to: Avatar, as: :all_ids

  @doc """
  Returns all avatar configurations.
  """
  @spec avatars() :: [Avatar.t()]
  defdelegate avatars, to: Avatar, as: :all

  @doc """
  Returns the avatar configuration for the given ID.
  """
  @spec get_avatar(pos_integer()) :: Avatar.t() | nil
  defdelegate get_avatar(id), to: Avatar, as: :get

  @doc """
  Returns the Dicebear URL for the given avatar ID.
  """
  @spec avatar_url(pos_integer()) :: String.t() | nil
  defdelegate avatar_url(id), to: Avatar, as: :url

  # ============================================================================
  # ID Generation
  # ============================================================================

  @doc """
  Generates a unique participant ID.
  """
  @spec generate_participant_id() :: String.t()
  def generate_participant_id do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(str) when is_binary(str), do: String.trim(str) == ""
  defp blank?(_), do: false

  @adjectives ~w(swift clever brave bright calm cool eager fast gentle happy jolly kind lively merry nice proud quick sharp smart sunny wise)
  @nouns ~w(falcon tiger eagle lion wolf bear hawk phoenix dragon turtle panda koala otter fox deer rabbit heron crane raven owl)

  defp generate_game_name do
    adjective = Enum.random(@adjectives)
    noun = Enum.random(@nouns)
    number = :rand.uniform(99)

    "#{String.capitalize(adjective)} #{String.capitalize(noun)} #{number}"
  end
end
