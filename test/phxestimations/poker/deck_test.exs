defmodule Phxestimations.Poker.DeckTest do
  use ExUnit.Case, async: true

  alias Phxestimations.Poker.Deck

  describe "types/0" do
    test "returns available deck types" do
      assert Deck.types() == [:fibonacci, :tshirt]
    end
  end

  describe "cards/1" do
    test "returns fibonacci cards" do
      cards = Deck.cards(:fibonacci)

      assert "0" in cards
      assert "1" in cards
      assert "2" in cards
      assert "3" in cards
      assert "5" in cards
      assert "8" in cards
      assert "13" in cards
      assert "21" in cards
      assert "34" in cards
      assert "∞" in cards
      assert "?" in cards
      assert "coffee" in cards
      assert "bug" in cards
      assert length(cards) == 13
    end

    test "returns tshirt cards" do
      cards = Deck.cards(:tshirt)

      assert "XS" in cards
      assert "S" in cards
      assert "M" in cards
      assert "L" in cards
      assert "XL" in cards
      assert "XXL" in cards
      assert "∞" in cards
      assert "?" in cards
      assert "coffee" in cards
      assert "bug" in cards
      assert length(cards) == 10
    end
  end

  describe "valid_card?/2" do
    test "returns true for valid fibonacci cards" do
      assert Deck.valid_card?(:fibonacci, "5")
      assert Deck.valid_card?(:fibonacci, "13")
      assert Deck.valid_card?(:fibonacci, "?")
      assert Deck.valid_card?(:fibonacci, "coffee")
    end

    test "returns false for invalid fibonacci cards" do
      refute Deck.valid_card?(:fibonacci, "4")
      refute Deck.valid_card?(:fibonacci, "XL")
      refute Deck.valid_card?(:fibonacci, "invalid")
    end

    test "returns true for valid tshirt cards" do
      assert Deck.valid_card?(:tshirt, "S")
      assert Deck.valid_card?(:tshirt, "XL")
      assert Deck.valid_card?(:tshirt, "?")
      assert Deck.valid_card?(:tshirt, "coffee")
    end

    test "returns false for invalid tshirt cards" do
      refute Deck.valid_card?(:tshirt, "5")
      refute Deck.valid_card?(:tshirt, "XXS")
      refute Deck.valid_card?(:tshirt, "invalid")
    end
  end

  describe "numeric_value/1" do
    test "returns numeric value for fibonacci cards" do
      assert Deck.numeric_value("0") == 0
      assert Deck.numeric_value("1") == 1
      assert Deck.numeric_value("5") == 5
      assert Deck.numeric_value("13") == 13
      assert Deck.numeric_value("34") == 34
    end

    test "returns nil for non-numeric cards" do
      assert Deck.numeric_value("?") == nil
      assert Deck.numeric_value("coffee") == nil
      assert Deck.numeric_value("∞") == nil
      assert Deck.numeric_value("bug") == nil
      assert Deck.numeric_value("XL") == nil
      assert Deck.numeric_value("invalid") == nil
    end
  end

  describe "numeric?/1" do
    test "returns true for numeric cards" do
      assert Deck.numeric?("0")
      assert Deck.numeric?("5")
      assert Deck.numeric?("21")
    end

    test "returns false for non-numeric cards" do
      refute Deck.numeric?("?")
      refute Deck.numeric?("coffee")
      refute Deck.numeric?("XL")
    end
  end

  describe "display_name/1" do
    test "returns human-readable names" do
      assert Deck.display_name(:fibonacci) == "Fibonacci"
      assert Deck.display_name(:tshirt) == "T-Shirt Sizes"
    end
  end
end
