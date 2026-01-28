defmodule PhxestimationsWeb.GameHelpers do
  @moduledoc """
  Test helpers for Planning Poker game scenarios.

  Provides conn/session builders, game scenario builders, LiveView action
  helpers, and custom assertions to reduce boilerplate in integration and
  LiveView tests.

  Automatically imported in all ConnCase tests.
  """

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import ExUnit.Assertions

  alias Phxestimations.Poker

  @endpoint PhxestimationsWeb.Endpoint

  # ============================================================================
  # Conn / Session Builders
  # ============================================================================

  @doc """
  Creates a conn that has been through the ParticipantSession plug.

  Returns `{conn, participant_id}`.

  ## Examples

      {conn, participant_id} = build_user_conn()
  """
  def build_user_conn do
    conn =
      build_conn()
      |> get("/")

    participant_id = Plug.Conn.get_session(conn, "participant_id")
    {conn, participant_id}
  end

  @doc """
  Creates N independent user connections, each with their own session.

  Returns a list of `{conn, participant_id}` tuples.

  ## Examples

      users = build_user_conns(3)
      [{conn1, pid1}, {conn2, pid2}, {conn3, pid3}] = users
  """
  def build_user_conns(n) when n > 0 do
    Enum.map(1..n, fn _i -> build_user_conn() end)
  end

  # ============================================================================
  # Game Scenario Builders
  # ============================================================================

  @doc """
  Shortcut for `Poker.create_game/2`. Returns the game_id.

  ## Examples

      game_id = create_test_game("Sprint 42", :fibonacci)
  """
  def create_test_game(name \\ "Test Game", deck_type \\ :fibonacci) do
    {:ok, game_id} = Poker.create_game(name, deck_type)
    game_id
  end

  @doc """
  Creates a game and joins N voters via the Poker API.

  Returns `%{game_id: String.t(), users: [%{conn: conn, participant_id: id, name: name}]}`.

  ## Options

    * `:name` - game name (default: "Test Game")
    * `:deck_type` - deck type (default: :fibonacci)
    * `:names` - list of participant names (default: ["Alice", "Bob", "Charlie", ...])

  ## Examples

      %{game_id: gid, users: users} = setup_game_with_voters(3)
      %{game_id: gid, users: users} = setup_game_with_voters(2, names: ["Foo", "Bar"])
  """
  def setup_game_with_voters(count, opts \\ []) do
    game_name = Keyword.get(opts, :name, "Test Game")
    deck_type = Keyword.get(opts, :deck_type, :fibonacci)
    names = Keyword.get(opts, :names, default_names(count))

    game_id = create_test_game(game_name, deck_type)

    users =
      names
      |> Enum.take(count)
      |> Enum.map(fn name ->
        {conn, participant_id} = build_user_conn()
        {:ok, _game} = Poker.join_game(game_id, participant_id, name, :voter)
        %{conn: conn, participant_id: participant_id, name: name}
      end)

    %{game_id: game_id, users: users}
  end

  @doc """
  Creates a game with both voters and spectators.

  Returns `%{game_id: id, voters: [...], spectators: [...]}` where each entry
  is `%{conn: conn, participant_id: id, name: name}`.

  ## Options

    * `:name` - game name (default: "Test Game")
    * `:deck_type` - deck type (default: :fibonacci)
    * `:voter_names` - names for voters (defaults provided)
    * `:spectator_names` - names for spectators (defaults provided)
  """
  def setup_game_with_mixed(voter_count, spectator_count, opts \\ []) do
    game_name = Keyword.get(opts, :name, "Test Game")
    deck_type = Keyword.get(opts, :deck_type, :fibonacci)
    voter_names = Keyword.get(opts, :voter_names, default_names(voter_count))

    spectator_names =
      Keyword.get(opts, :spectator_names, default_spectator_names(spectator_count))

    game_id = create_test_game(game_name, deck_type)

    voters =
      voter_names
      |> Enum.take(voter_count)
      |> Enum.map(fn name ->
        {conn, participant_id} = build_user_conn()
        {:ok, _game} = Poker.join_game(game_id, participant_id, name, :voter)
        %{conn: conn, participant_id: participant_id, name: name}
      end)

    spectators =
      spectator_names
      |> Enum.take(spectator_count)
      |> Enum.map(fn name ->
        {conn, participant_id} = build_user_conn()
        {:ok, _game} = Poker.join_game(game_id, participant_id, name, :spectator)
        %{conn: conn, participant_id: participant_id, name: name}
      end)

    %{game_id: game_id, voters: voters, spectators: spectators}
  end

  @doc """
  Mounts LiveView for each user. Returns list of `%{view: view, html: html}`.

  Each user map must have `:conn` key. The `game_id` is used to build the path.
  """
  def connect_users_to_game(users, game_id) do
    Enum.map(users, fn %{conn: conn} ->
      {:ok, view, html} = live(conn, "/games/#{game_id}")
      %{view: view, html: html}
    end)
  end

  # ============================================================================
  # LiveView Action Helpers
  # ============================================================================

  @doc "Clicks a card in the card deck."
  def vote_via_view(view, card_value) do
    view |> element("#card-#{card_value}") |> render_click()
  end

  @doc "Clicks the reveal button."
  def reveal_via_view(view) do
    view |> element("#reveal-btn") |> render_click()
  end

  @doc "Clicks the reset/new round button."
  def reset_via_view(view) do
    view |> element("#reset-btn") |> render_click()
  end

  @doc "Clicks the invite button."
  def show_invite_via_view(view) do
    view |> element("#invite-btn") |> render_click()
  end

  # ============================================================================
  # Custom Assertions
  # ============================================================================

  @doc "Asserts the game is in voting state (reveal button present)."
  def assert_voting_state(view) do
    assert has_element?(view, "#reveal-btn"),
           "Expected voting state (#reveal-btn present)"

    refute has_element?(view, "#reset-btn"),
           "Expected voting state but found #reset-btn"
  end

  @doc "Asserts the game is in revealed state (reset button present)."
  def assert_revealed_state(view) do
    assert has_element?(view, "#reset-btn"),
           "Expected revealed state (#reset-btn present)"

    refute has_element?(view, "#reveal-btn"),
           "Expected revealed state but found #reveal-btn"
  end

  @doc "Asserts a participant name is visible in the rendered view."
  def assert_participant_visible(view, name) do
    html = render(view)

    assert html =~ name,
           "Expected participant '#{name}' to be visible in the rendered view"
  end

  @doc """
  Asserts that the vote average is displayed and matches the expected value.

  The expected value should be a float (e.g., 6.0).
  """
  def assert_average_displayed(view, expected) do
    assert has_element?(view, "#vote-statistics"),
           "Expected #vote-statistics to be present"

    assert has_element?(view, "#vote-average"),
           "Expected #vote-average to be present"

    html = render(view)
    formatted = Float.round(expected / 1, 1) |> to_string()
    assert html =~ formatted, "Expected average #{formatted} to be displayed"
  end

  @doc "Asserts that no vote average is displayed."
  def refute_average_displayed(view) do
    refute has_element?(view, "#vote-average"),
           "Expected #vote-average to NOT be present"
  end

  # ============================================================================
  # Private
  # ============================================================================

  defp default_names(count) do
    all_names = ~w(Alice Bob Charlie Diana Eve Frank Grace Henry Ivy Jack)
    Enum.take(all_names, count)
  end

  defp default_spectator_names(count) do
    all_names = ~w(Observer Watcher Viewer Monitor)
    Enum.take(all_names, count)
  end
end
