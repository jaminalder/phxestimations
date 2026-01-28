defmodule Phxestimations.Poker.Game do
  @moduledoc """
  Represents a Planning Poker game session.

  A game has two states:
  - `:voting` - Participants are selecting their cards (votes hidden)
  - `:revealed` - All votes are visible and statistics are shown
  """

  alias Phxestimations.Poker.{Avatar, Deck, Participant}

  @type state :: :voting | :revealed

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          deck_type: Deck.deck_type(),
          state: state(),
          story_name: String.t() | nil,
          participants: %{String.t() => Participant.t()},
          used_avatars: MapSet.t(pos_integer()),
          created_at: DateTime.t()
        }

  @enforce_keys [:id, :name, :deck_type, :created_at]
  defstruct [
    :id,
    :name,
    :deck_type,
    :created_at,
    state: :voting,
    story_name: nil,
    participants: %{},
    used_avatars: MapSet.new()
  ]

  @doc """
  Creates a new game with the given name and deck type.
  """
  @spec new(String.t(), String.t(), Deck.deck_type()) :: t()
  def new(id, name, deck_type) do
    %__MODULE__{
      id: id,
      name: name,
      deck_type: deck_type,
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Adds a participant to the game.

  If the participant has an avatar_id, it will be added to used_avatars.
  """
  @spec add_participant(t(), Participant.t()) :: t()
  def add_participant(game, participant) do
    game = %{game | participants: Map.put(game.participants, participant.id, participant)}

    if participant.avatar_id do
      claim_avatar(game, participant.avatar_id)
    else
      game
    end
  end

  @doc """
  Removes a participant from the game.

  If the participant had an avatar, it will be released for others to use.
  """
  @spec remove_participant(t(), String.t()) :: t()
  def remove_participant(game, participant_id) do
    case Map.get(game.participants, participant_id) do
      nil ->
        game

      participant ->
        game = %{game | participants: Map.delete(game.participants, participant_id)}

        if participant.avatar_id do
          release_avatar(game, participant.avatar_id)
        else
          game
        end
    end
  end

  @doc """
  Returns the list of available avatar IDs (not currently in use).
  """
  @spec available_avatars(t()) :: [pos_integer()]
  def available_avatars(game) do
    Avatar.all_ids()
    |> Enum.reject(&MapSet.member?(game.used_avatars, &1))
  end

  @doc """
  Claims an avatar by adding it to the used_avatars set.
  """
  @spec claim_avatar(t(), pos_integer()) :: t()
  def claim_avatar(game, avatar_id) do
    %{game | used_avatars: MapSet.put(game.used_avatars, avatar_id)}
  end

  @doc """
  Releases an avatar by removing it from the used_avatars set.
  """
  @spec release_avatar(t(), pos_integer()) :: t()
  def release_avatar(game, avatar_id) do
    %{game | used_avatars: MapSet.delete(game.used_avatars, avatar_id)}
  end

  @doc """
  Updates a participant in the game.
  """
  @spec update_participant(t(), String.t(), (Participant.t() -> Participant.t())) :: t()
  def update_participant(game, participant_id, update_fn) do
    case Map.get(game.participants, participant_id) do
      nil ->
        game

      participant ->
        updated = update_fn.(participant)
        %{game | participants: Map.put(game.participants, participant_id, updated)}
    end
  end

  @doc """
  Casts a vote for a participant.
  Only works in `:voting` state and for valid cards.
  """
  @spec cast_vote(t(), String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def cast_vote(%__MODULE__{state: :revealed}, _participant_id, _card) do
    {:error, :already_revealed}
  end

  def cast_vote(game, participant_id, card) do
    if Deck.valid_card?(game.deck_type, card) do
      updated_game = update_participant(game, participant_id, &Participant.vote(&1, card))
      {:ok, updated_game}
    else
      {:error, :invalid_card}
    end
  end

  @doc """
  Reveals all votes. Changes state from `:voting` to `:revealed`.
  """
  @spec reveal_votes(t()) :: t()
  def reveal_votes(%__MODULE__{state: :voting} = game) do
    %{game | state: :revealed}
  end

  def reveal_votes(game), do: game

  @doc """
  Resets the game for a new voting round.
  Clears all votes and sets state back to `:voting`.
  """
  @spec reset_round(t()) :: t()
  def reset_round(game) do
    cleared_participants =
      game.participants
      |> Map.new(fn {id, participant} -> {id, Participant.clear_vote(participant)} end)

    %{game | state: :voting, participants: cleared_participants, story_name: nil}
  end

  @doc """
  Sets the story name for the current round.
  """
  @spec set_story_name(t(), String.t() | nil) :: t()
  def set_story_name(game, story_name) do
    %{game | story_name: story_name}
  end

  @doc """
  Returns all voters (participants with role `:voter`).
  """
  @spec voters(t()) :: [Participant.t()]
  def voters(game) do
    game.participants
    |> Map.values()
    |> Enum.filter(&Participant.voter?/1)
  end

  @doc """
  Returns all spectators (participants with role `:spectator`).
  """
  @spec spectators(t()) :: [Participant.t()]
  def spectators(game) do
    game.participants
    |> Map.values()
    |> Enum.filter(&Participant.spectator?/1)
  end

  @doc """
  Returns all connected participants.
  """
  @spec connected_participants(t()) :: [Participant.t()]
  def connected_participants(game) do
    game.participants
    |> Map.values()
    |> Enum.filter(& &1.connected)
  end

  @doc """
  Checks if all connected voters have voted.
  """
  @spec all_voters_voted?(t()) :: boolean()
  def all_voters_voted?(game) do
    connected_voters =
      game
      |> voters()
      |> Enum.filter(& &1.connected)

    case connected_voters do
      [] -> false
      voters -> Enum.all?(voters, &Participant.voted?/1)
    end
  end

  @doc """
  Checks if any voter has voted.
  """
  @spec any_votes?(t()) :: boolean()
  def any_votes?(game) do
    game
    |> voters()
    |> Enum.any?(&Participant.voted?/1)
  end

  @doc """
  Calculates voting statistics.
  Returns `{average, distribution}` where:
  - `average` is the mean of numeric votes (nil if no numeric votes)
  - `distribution` is a map of card -> count
  """
  @spec calculate_statistics(t()) :: {float() | nil, %{String.t() => non_neg_integer()}}
  def calculate_statistics(game) do
    votes =
      game
      |> voters()
      |> Enum.filter(&Participant.voted?/1)
      |> Enum.map(& &1.vote)

    distribution =
      votes
      |> Enum.frequencies()
      |> Enum.sort_by(fn {card, _count} ->
        # Sort by numeric value if available, otherwise put at end
        Deck.numeric_value(card) || 1000
      end)
      |> Map.new()

    numeric_votes =
      votes
      |> Enum.map(&Deck.numeric_value/1)
      |> Enum.reject(&is_nil/1)

    average =
      case numeric_votes do
        [] -> nil
        values -> Float.round(Enum.sum(values) / length(values), 1)
      end

    {average, distribution}
  end

  @doc """
  Returns the number of participants in the game.
  """
  @spec participant_count(t()) :: non_neg_integer()
  def participant_count(game) do
    map_size(game.participants)
  end

  @doc """
  Checks if the game is empty (no participants).
  """
  @spec empty?(t()) :: boolean()
  def empty?(game) do
    participant_count(game) == 0
  end

  @doc """
  Gets a participant by ID.
  """
  @spec get_participant(t(), String.t()) :: Participant.t() | nil
  def get_participant(game, participant_id) do
    Map.get(game.participants, participant_id)
  end

  @doc """
  Checks if a participant exists in the game.
  """
  @spec has_participant?(t(), String.t()) :: boolean()
  def has_participant?(game, participant_id) do
    Map.has_key?(game.participants, participant_id)
  end
end
