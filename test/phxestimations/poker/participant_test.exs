defmodule Phxestimations.Poker.ParticipantTest do
  use ExUnit.Case, async: true

  alias Phxestimations.Poker.Participant

  describe "new/3" do
    test "creates a voter participant" do
      participant = Participant.new("p1", "Alice", :voter)

      assert participant.id == "p1"
      assert participant.name == "Alice"
      assert participant.role == :voter
      assert participant.vote == nil
      assert participant.connected == true
    end

    test "creates a spectator participant" do
      participant = Participant.new("p2", "Bob", :spectator)

      assert participant.id == "p2"
      assert participant.name == "Bob"
      assert participant.role == :spectator
      assert participant.vote == nil
      assert participant.connected == true
    end
  end

  describe "vote/2" do
    test "records vote for voter" do
      participant = Participant.new("p1", "Alice", :voter)
      voted = Participant.vote(participant, "5")

      assert voted.vote == "5"
    end

    test "ignores vote for spectator" do
      participant = Participant.new("p1", "Bob", :spectator)
      voted = Participant.vote(participant, "5")

      assert voted.vote == nil
    end

    test "can change vote" do
      participant =
        Participant.new("p1", "Alice", :voter)
        |> Participant.vote("5")
        |> Participant.vote("8")

      assert participant.vote == "8"
    end
  end

  describe "clear_vote/1" do
    test "clears existing vote" do
      participant =
        Participant.new("p1", "Alice", :voter)
        |> Participant.vote("5")
        |> Participant.clear_vote()

      assert participant.vote == nil
    end

    test "handles already clear vote" do
      participant =
        Participant.new("p1", "Alice", :voter)
        |> Participant.clear_vote()

      assert participant.vote == nil
    end
  end

  describe "set_connected/2" do
    test "sets connected to false" do
      participant =
        Participant.new("p1", "Alice", :voter)
        |> Participant.set_connected(false)

      assert participant.connected == false
    end

    test "sets connected to true" do
      participant =
        Participant.new("p1", "Alice", :voter)
        |> Participant.set_connected(false)
        |> Participant.set_connected(true)

      assert participant.connected == true
    end
  end

  describe "voted?/1" do
    test "returns false when no vote" do
      participant = Participant.new("p1", "Alice", :voter)
      refute Participant.voted?(participant)
    end

    test "returns true when voted" do
      participant =
        Participant.new("p1", "Alice", :voter)
        |> Participant.vote("5")

      assert Participant.voted?(participant)
    end
  end

  describe "voter?/1" do
    test "returns true for voter" do
      participant = Participant.new("p1", "Alice", :voter)
      assert Participant.voter?(participant)
    end

    test "returns false for spectator" do
      participant = Participant.new("p1", "Bob", :spectator)
      refute Participant.voter?(participant)
    end
  end

  describe "spectator?/1" do
    test "returns true for spectator" do
      participant = Participant.new("p1", "Bob", :spectator)
      assert Participant.spectator?(participant)
    end

    test "returns false for voter" do
      participant = Participant.new("p1", "Alice", :voter)
      refute Participant.spectator?(participant)
    end
  end

  describe "initial/1" do
    test "returns uppercase first letter" do
      participant = Participant.new("p1", "alice", :voter)
      assert Participant.initial(participant) == "A"
    end

    test "handles already uppercase" do
      participant = Participant.new("p1", "Bob", :voter)
      assert Participant.initial(participant) == "B"
    end

    test "handles names with leading spaces" do
      participant = Participant.new("p1", "  Charlie", :voter)
      assert Participant.initial(participant) == "C"
    end
  end
end
