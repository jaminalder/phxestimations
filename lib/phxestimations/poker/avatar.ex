defmodule Phxestimations.Poker.Avatar do
  @moduledoc """
  Defines preset avatar options for Planning Poker participants.

  Uses Dicebear bottts-style robot avatars with 7 distinct visual presets.
  Each avatar has a unique color scheme and robot appearance.
  """

  @type avatar_id :: 1..7

  @type t :: %{
          id: avatar_id(),
          name: String.t(),
          color: String.t(),
          eyes: String.t(),
          mouth: String.t(),
          sides: String.t(),
          top: String.t()
        }

  @avatars %{
    1 => %{
      id: 1,
      name: "Sunny",
      color: "ffb300",
      eyes: "happy",
      mouth: "smile01",
      sides: "antenna01",
      top: "bulb01"
    },
    2 => %{
      id: 2,
      name: "Ocean",
      color: "1e88e5",
      eyes: "eva",
      mouth: "square01",
      sides: "cables01",
      top: "radar"
    },
    3 => %{
      id: 3,
      name: "Forest",
      color: "43a047",
      eyes: "glow",
      mouth: "grill01",
      sides: "round",
      top: "horns"
    },
    4 => %{
      id: 4,
      name: "Sunset",
      color: "f4511e",
      eyes: "bulging",
      mouth: "bite",
      sides: "squareAssymetric",
      top: "antenna"
    },
    5 => %{
      id: 5,
      name: "Royal",
      color: "8e24aa",
      eyes: "hearts",
      mouth: "smile02",
      sides: "square",
      top: "pyramid"
    },
    6 => %{
      id: 6,
      name: "Steel",
      color: "546e7a",
      eyes: "robocop",
      mouth: "diagram",
      sides: "antenna02",
      top: "lights"
    },
    7 => %{
      id: 7,
      name: "Ruby",
      color: "e53935",
      eyes: "sensor",
      mouth: "grill02",
      sides: "cables02",
      top: "glowingBulb01"
    }
  }

  @doc """
  Returns all available avatar IDs.

  ## Examples

      iex> Avatar.all_ids()
      [1, 2, 3, 4, 5, 6, 7]
  """
  @spec all_ids() :: [avatar_id()]
  def all_ids, do: [1, 2, 3, 4, 5, 6, 7]

  @doc """
  Returns all avatar configurations.

  ## Examples

      iex> Avatar.all() |> length()
      7
  """
  @spec all() :: [t()]
  def all do
    all_ids()
    |> Enum.map(&get/1)
  end

  @doc """
  Returns the avatar configuration for the given ID.

  Returns `nil` if the ID is invalid.

  ## Examples

      iex> Avatar.get(1)
      %{id: 1, name: "Sunny", color: "ffb300", eyes: "happy", mouth: "smile01", sides: "antenna01", top: "bulb01"}

      iex> Avatar.get(99)
      nil
  """
  @spec get(avatar_id()) :: t() | nil
  def get(id) when id in 1..7, do: Map.get(@avatars, id)
  def get(_), do: nil

  @doc """
  Generates the Dicebear URL for the given avatar ID.

  Returns `nil` if the ID is invalid.

  ## Examples

      iex> Avatar.url(1) |> String.starts_with?("https://api.dicebear.com")
      true

      iex> Avatar.url(99)
      nil
  """
  @spec url(avatar_id()) :: String.t() | nil
  def url(id) do
    case get(id) do
      nil ->
        nil

      avatar ->
        "https://api.dicebear.com/9.x/bottts/svg?" <>
          URI.encode_query(%{
            "baseColor" => avatar.color,
            "eyes" => avatar.eyes,
            "mouth" => avatar.mouth,
            "sides" => avatar.sides,
            "top" => avatar.top
          })
    end
  end

  @doc """
  Checks if the given ID is a valid avatar ID.

  ## Examples

      iex> Avatar.valid?(1)
      true

      iex> Avatar.valid?(99)
      false
  """
  @spec valid?(any()) :: boolean()
  def valid?(id) when id in 1..7, do: true
  def valid?(_), do: false
end
