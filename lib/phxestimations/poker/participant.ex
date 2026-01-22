defmodule Phxestimations.Poker.Participant do
  @moduledoc """
  Represents a participant in a Planning Poker game.

  Participants can have two roles:
  - `:voter` - Can select cards and participate in estimation
  - `:spectator` - Can watch but does not vote (e.g., Product Owner)
  """

  @type role :: :voter | :spectator

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          role: role(),
          vote: String.t() | nil,
          connected: boolean()
        }

  @enforce_keys [:id, :name, :role]
  defstruct [:id, :name, :role, vote: nil, connected: true]

  @doc """
  Creates a new participant.
  """
  @spec new(String.t(), String.t(), role()) :: t()
  def new(id, name, role) when role in [:voter, :spectator] do
    %__MODULE__{
      id: id,
      name: name,
      role: role
    }
  end

  @doc """
  Records a vote for the participant.
  Only voters can vote; spectators return unchanged.
  """
  @spec vote(t(), String.t()) :: t()
  def vote(%__MODULE__{role: :voter} = participant, card) do
    %{participant | vote: card}
  end

  def vote(%__MODULE__{role: :spectator} = participant, _card) do
    participant
  end

  @doc """
  Clears the participant's vote.
  """
  @spec clear_vote(t()) :: t()
  def clear_vote(participant) do
    %{participant | vote: nil}
  end

  @doc """
  Sets the connection status of the participant.
  """
  @spec set_connected(t(), boolean()) :: t()
  def set_connected(participant, connected) do
    %{participant | connected: connected}
  end

  @doc """
  Checks if the participant has voted.
  """
  @spec voted?(t()) :: boolean()
  def voted?(%__MODULE__{vote: vote}), do: vote != nil

  @doc """
  Checks if the participant is a voter.
  """
  @spec voter?(t()) :: boolean()
  def voter?(%__MODULE__{role: role}), do: role == :voter

  @doc """
  Checks if the participant is a spectator.
  """
  @spec spectator?(t()) :: boolean()
  def spectator?(%__MODULE__{role: role}), do: role == :spectator

  @doc """
  Returns the initial letter of the participant's name for avatar display.
  """
  @spec initial(t()) :: String.t()
  def initial(%__MODULE__{name: name}) do
    name
    |> String.trim()
    |> String.first()
    |> String.upcase()
  end
end
