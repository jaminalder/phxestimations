defmodule Phxestimations.Poker.AvatarTest do
  use ExUnit.Case, async: true

  alias Phxestimations.Poker.Avatar

  describe "all_ids/0" do
    test "returns all 7 avatar IDs" do
      assert Avatar.all_ids() == [1, 2, 3, 4, 5, 6, 7]
    end
  end

  describe "all/0" do
    test "returns all avatar configurations" do
      avatars = Avatar.all()
      assert length(avatars) == 7
      assert Enum.all?(avatars, &is_map/1)
    end
  end

  describe "get/1" do
    test "returns avatar config for valid ID" do
      avatar = Avatar.get(1)
      assert avatar.id == 1
      assert avatar.name == "Sunny"
      assert avatar.color == "ffb300"
    end

    test "returns nil for invalid ID" do
      assert Avatar.get(0) == nil
      assert Avatar.get(8) == nil
      assert Avatar.get(-1) == nil
      assert Avatar.get("invalid") == nil
    end

    test "each avatar has required fields" do
      for id <- Avatar.all_ids() do
        avatar = Avatar.get(id)
        assert Map.has_key?(avatar, :id)
        assert Map.has_key?(avatar, :name)
        assert Map.has_key?(avatar, :color)
        assert Map.has_key?(avatar, :eyes)
        assert Map.has_key?(avatar, :mouth)
        assert Map.has_key?(avatar, :sides)
        assert Map.has_key?(avatar, :top)
      end
    end
  end

  describe "url/1" do
    test "generates Dicebear URL for valid ID" do
      url = Avatar.url(1)
      assert String.starts_with?(url, "https://api.dicebear.com/9.x/bottts/svg?")
      assert url =~ "baseColor=ffb300"
      assert url =~ "eyes=happy"
    end

    test "returns nil for invalid ID" do
      assert Avatar.url(0) == nil
      assert Avatar.url(99) == nil
    end
  end

  describe "valid?/1" do
    test "returns true for valid IDs" do
      for id <- 1..7 do
        assert Avatar.valid?(id)
      end
    end

    test "returns false for invalid IDs" do
      refute Avatar.valid?(0)
      refute Avatar.valid?(8)
      refute Avatar.valid?(-1)
      refute Avatar.valid?("string")
      refute Avatar.valid?(nil)
    end
  end
end
