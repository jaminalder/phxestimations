defmodule PhxestimationsWeb.GameLive.Show do
  use PhxestimationsWeb, :live_view

  alias Phxestimations.Poker
  alias Phxestimations.Poker.Game
  alias PhxestimationsWeb.Plugs.ParticipantSession

  @impl true
  def mount(%{"id" => game_id}, session, socket) do
    participant_id = ParticipantSession.get_participant_id(session)

    case Poker.get_game(game_id) do
      {:ok, game} ->
        if Map.has_key?(game.participants, participant_id) do
          if connected?(socket) do
            Poker.subscribe(game_id)
            Poker.set_participant_connected(game_id, participant_id, true)
          end

          {:ok, game} = Poker.get_game(game_id)

          {:ok,
           socket
           |> assign(
             page_title: game.name,
             game_id: game_id,
             game: game,
             participant_id: participant_id,
             current_participant: game.participants[participant_id],
             cards: Poker.deck_cards(game.deck_type),
             show_invite: false,
             game_url: url(socket, ~p"/games/#{game_id}/join")
           )
           |> assign_derived(game)}
        else
          {:ok, push_navigate(socket, to: "/games/#{game_id}/join")}
        end

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns[:participant_id] && socket.assigns[:game_id] do
      Poker.set_participant_connected(
        socket.assigns.game_id,
        socket.assigns.participant_id,
        false
      )
    end

    :ok
  end

  # Event Handlers
  @impl true
  def handle_event("vote", %{"card" => card}, socket) do
    case Poker.cast_vote(socket.assigns.game_id, socket.assigns.participant_id, card) do
      {:ok, _game} -> {:noreply, socket}
      {:error, _reason} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("reveal", _params, socket) do
    {:ok, _game} = Poker.reveal_votes(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:ok, _game} = Poker.reset_round(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_story", %{"story" => story_name}, socket) do
    {:ok, _game} = Poker.set_story_name(socket.assigns.game_id, story_name)
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_invite", _params, socket) do
    {:noreply, assign(socket, show_invite: true)}
  end

  @impl true
  def handle_event("close_invite", _params, socket) do
    {:noreply, assign(socket, show_invite: false)}
  end

  # PubSub Handlers
  @impl true
  def handle_info({:participant_joined, _participant}, socket) do
    game = update_game_state(socket)

    {:noreply,
     socket
     |> assign(game: game, current_participant: get_current_participant(socket, game))
     |> assign_derived(game)}
  end

  @impl true
  def handle_info({:participant_left, _participant_id}, socket) do
    game = update_game_state(socket)

    {:noreply,
     socket
     |> assign(game: game, current_participant: get_current_participant(socket, game))
     |> assign_derived(game)}
  end

  @impl true
  def handle_info({:participant_connected, _participant_id}, socket) do
    game = update_game_state(socket)
    {:noreply, socket |> assign(game: game) |> assign_derived(game)}
  end

  @impl true
  def handle_info({:participant_reconnected, _participant_id}, socket) do
    game = update_game_state(socket)
    {:noreply, socket |> assign(game: game) |> assign_derived(game)}
  end

  @impl true
  def handle_info({:participant_disconnected, _participant_id}, socket) do
    game = update_game_state(socket)
    {:noreply, socket |> assign(game: game) |> assign_derived(game)}
  end

  @impl true
  def handle_info({:vote_cast, _participant_id}, socket) do
    game = update_game_state(socket)

    {:noreply,
     socket
     |> assign(game: game, current_participant: get_current_participant(socket, game))
     |> assign_derived(game)}
  end

  @impl true
  def handle_info({:votes_revealed, _game}, socket) do
    game = update_game_state(socket)
    {:noreply, socket |> assign(game: game) |> assign_derived(game)}
  end

  @impl true
  def handle_info({:round_reset, _game}, socket) do
    game = update_game_state(socket)

    {:noreply,
     socket
     |> assign(game: game, current_participant: get_current_participant(socket, game))
     |> assign_derived(game)}
  end

  @impl true
  def handle_info({:story_name_changed, _story_name}, socket) do
    game = update_game_state(socket)
    {:noreply, assign(socket, game: game)}
  end

  # Private Functions

  defp update_game_state(socket) do
    case Poker.get_game(socket.assigns.game_id) do
      {:ok, game} -> game
      {:error, _} -> socket.assigns.game
    end
  end

  defp get_current_participant(socket, game) do
    Map.get(game.participants, socket.assigns.participant_id)
  end

  defp assign_derived(socket, game) do
    voters = voters(game)
    spectators = spectators(game)
    vote_count = Enum.count(voters, & &1.vote)
    total_voters = length(voters)
    all_voted? = voters != [] && Enum.all?(voters, & &1.vote)

    statistics =
      if game.state == :revealed do
        {average, distribution} = Game.calculate_statistics(game)
        %{average: average, distribution: distribution}
      else
        nil
      end

    assign(socket,
      voters: voters,
      spectators: spectators,
      vote_count: vote_count,
      total_voters: total_voters,
      all_voted?: all_voted?,
      statistics: statistics
    )
  end

  defp voters(game) do
    game.participants
    |> Enum.filter(fn {_id, p} -> p.role == :voter end)
    |> Enum.map(fn {_id, p} -> p end)
    |> Enum.sort_by(& &1.name)
  end

  defp spectators(game) do
    game.participants
    |> Enum.filter(fn {_id, p} -> p.role == :spectator end)
    |> Enum.map(fn {_id, p} -> p end)
    |> Enum.sort_by(& &1.name)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="game-room" class="min-h-screen flex flex-col">
        <.game_header game={@game} />

        <main class="flex-1 flex flex-col">
          <.poker_table
            voters={@voters}
            spectators={@spectators}
            current_participant_id={@participant_id}
            game_state={@game.state}
            vote_count={@vote_count}
            total_voters={@total_voters}
            statistics={@statistics}
          />

          <.card_deck
            :if={@current_participant && @current_participant.role == :voter}
            cards={@cards}
            selected_card={@current_participant.vote}
            state={@game.state}
          />

          <.game_controls state={@game.state} all_voted?={@all_voted?} />
        </main>

        <.invite_modal game_url={@game_url} show={@show_invite} />
      </div>
    </Layouts.app>
    """
  end
end
