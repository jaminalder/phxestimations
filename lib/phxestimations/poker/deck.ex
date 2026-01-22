defmodule Phxestimations.Poker.Deck do
  @moduledoc """
  Defines card decks for Planning Poker estimation.

  Supports two deck types:
  - `:fibonacci` - Standard Fibonacci sequence for story points
  - `:tshirt` - T-Shirt sizes for relative sizing
  """

  @type deck_type :: :fibonacci | :tshirt
  @type card :: String.t()

  @fibonacci ["0", "1", "2", "3", "5", "8", "13", "21", "34", "55", "89", "?", "coffee"]
  @tshirt ["XS", "S", "M", "L", "XL", "XXL", "?", "coffee"]

  @fibonacci_values %{
    "0" => 0,
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "5" => 5,
    "8" => 8,
    "13" => 13,
    "21" => 21,
    "34" => 34,
    "55" => 55,
    "89" => 89
  }

  @doc """
  Returns all available deck types.
  """
  @spec types() :: [deck_type()]
  def types, do: [:fibonacci, :tshirt]

  @doc """
  Returns the list of cards for the given deck type.
  """
  @spec cards(deck_type()) :: [card()]
  def cards(:fibonacci), do: @fibonacci
  def cards(:tshirt), do: @tshirt

  @doc """
  Checks if a card is valid for the given deck type.
  """
  @spec valid_card?(deck_type(), card()) :: boolean()
  def valid_card?(deck_type, card), do: card in cards(deck_type)

  @doc """
  Returns the numeric value of a card for average calculation.
  Returns `nil` for non-numeric cards (?, coffee, t-shirt sizes).
  """
  @spec numeric_value(card()) :: number() | nil
  def numeric_value(card) do
    Map.get(@fibonacci_values, card)
  end

  @doc """
  Checks if a card has a numeric value (can be included in average).
  """
  @spec numeric?(card()) :: boolean()
  def numeric?(card), do: numeric_value(card) != nil

  @doc """
  Returns a human-readable name for a deck type.
  """
  @spec display_name(deck_type()) :: String.t()
  def display_name(:fibonacci), do: "Fibonacci"
  def display_name(:tshirt), do: "T-Shirt Sizes"
end
