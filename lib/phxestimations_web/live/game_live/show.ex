defmodule PhxestimationsWeb.GameLive.Show do
  use PhxestimationsWeb, :live_view

  alias Phxestimations.Poker
  alias PhxestimationsWeb.Plugs.ParticipantSession

  @impl true
  def mount(%{"id" => game_id}, session, socket) do
    participant_id = ParticipantSession.get_participant_id(session)

    case Poker.get_game(game_id) do
      {:ok, game} ->
        # Check if participant is already in the game
        if Map.has_key?(game.participants, participant_id) do
          if connected?(socket) do
            Poker.subscribe(game_id)
            Poker.set_participant_connected(game_id, participant_id, true)
          end

          {:ok, game} = Poker.get_game(game_id)

          {:ok,
           assign(socket,
             page_title: game.name,
             game_id: game_id,
             game: game,
             participant_id: participant_id,
             current_participant: game.participants[participant_id],
             cards: Poker.deck_cards(game.deck_type)
           )}
        else
          # Not in game, redirect to join
          {:ok,
           socket
           |> push_navigate(to: "/games/#{game_id}/join")}
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
      {:ok, _game} ->
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, socket}
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

  # PubSub Handlers
  @impl true
  def handle_info({:participant_joined, _participant}, socket) do
    game = update_game_state(socket)

    {:noreply,
     assign(socket, game: game, current_participant: get_current_participant(socket, game))}
  end

  @impl true
  def handle_info({:participant_left, _participant_id}, socket) do
    game = update_game_state(socket)

    {:noreply,
     assign(socket, game: game, current_participant: get_current_participant(socket, game))}
  end

  @impl true
  def handle_info({:participant_connected, _participant_id}, socket) do
    game = update_game_state(socket)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:participant_reconnected, _participant_id}, socket) do
    game = update_game_state(socket)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:participant_disconnected, _participant_id}, socket) do
    game = update_game_state(socket)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:vote_cast, _participant_id}, socket) do
    game = update_game_state(socket)

    {:noreply,
     assign(socket, game: game, current_participant: get_current_participant(socket, game))}
  end

  @impl true
  def handle_info({:votes_revealed, _game}, socket) do
    game = update_game_state(socket)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_info({:round_reset, _game}, socket) do
    game = update_game_state(socket)

    {:noreply,
     assign(socket, game: game, current_participant: get_current_participant(socket, game))}
  end

  @impl true
  def handle_info({:story_name_changed, _story_name}, socket) do
    game = update_game_state(socket)
    {:noreply, assign(socket, game: game)}
  end

  defp update_game_state(socket) do
    case Poker.get_game(socket.assigns.game_id) do
      {:ok, game} -> game
      {:error, _} -> socket.assigns.game
    end
  end

  defp get_current_participant(socket, game) do
    Map.get(game.participants, socket.assigns.participant_id)
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

  defp vote_count(game) do
    voters(game)
    |> Enum.count(& &1.vote)
  end

  defp total_voters(game) do
    voters(game) |> length()
  end

  defp all_voted?(game) do
    voters = voters(game)
    voters != [] && Enum.all?(voters, & &1.vote)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="game-room" class="min-h-screen flex flex-col">
        <!-- Header -->
        <header class="border-b border-slate-700/50 bg-slate-800/30 backdrop-blur-sm">
          <div class="max-w-7xl mx-auto px-4 py-4">
            <div class="flex items-center justify-between">
              <div>
                <h1
                  id="game-title"
                  class="text-xl font-bold text-white"
                  style="font-family: var(--font-display);"
                >
                  {@game.name}
                </h1>
                <p class="text-sm text-slate-400">
                  {Poker.deck_display_name(@game.deck_type)} •
                  <span :if={@game.story_name} class="text-blue-400">{@game.story_name}</span>
                  <span :if={!@game.story_name} class="text-slate-500">No story set</span>
                </p>
              </div>
              <div class="flex items-center gap-3">
                <button
                  id="invite-btn"
                  type="button"
                  class={[
                    "inline-flex items-center gap-2 px-4 py-2 rounded-lg",
                    "bg-slate-700/50 hover:bg-slate-600/50 text-slate-300 hover:text-white",
                    "border border-slate-600/50",
                    "transition-all duration-150"
                  ]}
                >
                  <.icon name="hero-link" class="w-4 h-4" /> Invite
                </button>
              </div>
            </div>
          </div>
        </header>
        
    <!-- Main content -->
        <main class="flex-1 flex flex-col">
          <!-- Poker table area -->
          <div id="poker-table" class="flex-1 flex items-center justify-center p-8">
            <div class="w-full max-w-4xl">
              <!-- Voting status -->
              <div class="text-center mb-8">
                <div :if={@game.state == :voting} class="space-y-2">
                  <p class="text-slate-400">
                    <span class="text-2xl font-bold text-white">{vote_count(@game)}</span>
                    <span class="text-slate-500">/ {total_voters(@game)}</span> voted
                  </p>
                  <div class="flex items-center justify-center gap-2">
                    <div class={[
                      "h-2 rounded-full bg-slate-700 w-48 overflow-hidden"
                    ]}>
                      <div
                        class="h-full bg-gradient-to-r from-blue-500 to-emerald-500 transition-all duration-300"
                        style={"width: #{if total_voters(@game) > 0, do: vote_count(@game) / total_voters(@game) * 100, else: 0}%"}
                      />
                    </div>
                  </div>
                </div>
                <div :if={@game.state == :revealed} class="space-y-2">
                  <p class="text-lg font-semibold text-emerald-400">Votes Revealed!</p>
                </div>
              </div>
              
    <!-- Participants grid -->
              <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 mb-8">
                <%= for voter <- voters(@game) do %>
                  <div
                    id={"participant-#{voter.id}"}
                    class={[
                      "relative p-4 rounded-xl text-center",
                      "bg-slate-800/50 border",
                      if(voter.id == @participant_id,
                        do: "border-blue-500/50",
                        else: "border-slate-700/50"
                      ),
                      if(!voter.connected, do: "opacity-50")
                    ]}
                  >
                    <!-- Card -->
                    <div class="mb-3">
                      <div
                        id={"participant-#{voter.id}-card"}
                        class={[
                          "poker-card w-12 h-16 mx-auto rounded-lg flex items-center justify-center",
                          "text-lg font-bold",
                          cond do
                            @game.state == :revealed && voter.vote ->
                              "bg-gradient-to-br from-emerald-500 to-emerald-600 text-white flipped"

                            voter.vote ->
                              "bg-gradient-to-br from-blue-500 to-blue-600 text-white"

                            true ->
                              "bg-slate-700/50 border-2 border-dashed border-slate-600 text-slate-500"
                          end
                        ]}
                      >
                        <%= if @game.state == :revealed && voter.vote do %>
                          {voter.vote}
                        <% else %>
                          <%= if voter.vote do %>
                            <.icon name="hero-check" class="w-5 h-5" />
                          <% else %>
                            ?
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                    
    <!-- Name -->
                    <p class={[
                      "text-sm font-medium truncate",
                      if(voter.connected, do: "text-white", else: "text-slate-500")
                    ]}>
                      {voter.name}
                      <span :if={voter.id == @participant_id} class="text-blue-400">(you)</span>
                    </p>
                    <p :if={!voter.connected} class="text-xs text-slate-500">disconnected</p>
                  </div>
                <% end %>
              </div>
              
    <!-- Spectators -->
              <div :if={spectators(@game) != []} class="text-center text-sm text-slate-500">
                <.icon name="hero-eye" class="w-4 h-4 inline" />
                <span class="ml-1">
                  Spectators: {Enum.map(spectators(@game), & &1.name) |> Enum.join(", ")}
                </span>
              </div>
            </div>
          </div>
          
    <!-- Card selection (for voters) -->
          <div
            :if={@current_participant && @current_participant.role == :voter}
            id="card-deck"
            class="border-t border-slate-700/50 bg-slate-800/30 backdrop-blur-sm p-6"
          >
            <div class="max-w-4xl mx-auto">
              <div :if={@game.state == :voting} class="flex flex-wrap justify-center gap-2">
                <%= for card <- @cards do %>
                  <button
                    id={"card-#{card}"}
                    phx-click="vote"
                    phx-value-card={card}
                    class={[
                      "w-14 h-20 rounded-lg font-bold text-lg",
                      "transition-all duration-150 hover:-translate-y-1",
                      "focus:outline-none focus:ring-2 focus:ring-blue-400",
                      if(@current_participant.vote == card,
                        do:
                          "bg-gradient-to-br from-blue-500 to-blue-600 text-white shadow-lg shadow-blue-500/25 -translate-y-1",
                        else:
                          "bg-slate-700/50 hover:bg-slate-600/50 text-white border border-slate-600/50"
                      )
                    ]}
                  >
                    {card}
                  </button>
                <% end %>
              </div>
              <div :if={@game.state == :revealed} class="text-center text-slate-400">
                Votes have been revealed. Start a new round to vote again.
              </div>
            </div>
          </div>
          
    <!-- Controls -->
          <div class="border-t border-slate-700/50 bg-slate-900/50 p-4">
            <div class="max-w-4xl mx-auto flex items-center justify-center gap-4">
              <button
                :if={@game.state == :voting}
                id="reveal-btn"
                phx-click="reveal"
                disabled={!all_voted?(@game)}
                class={[
                  "inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold",
                  "transition-all duration-150",
                  if(all_voted?(@game),
                    do:
                      "bg-emerald-500 hover:bg-emerald-400 text-white shadow-lg shadow-emerald-500/25",
                    else: "bg-slate-700 text-slate-400 cursor-not-allowed"
                  )
                ]}
              >
                <.icon name="hero-eye" class="w-5 h-5" /> Reveal Votes
              </button>

              <button
                :if={@game.state == :revealed}
                id="reset-btn"
                phx-click="reset"
                class={[
                  "inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold",
                  "bg-blue-500 hover:bg-blue-400 text-white",
                  "shadow-lg shadow-blue-500/25",
                  "transition-all duration-150"
                ]}
              >
                <.icon name="hero-arrow-path" class="w-5 h-5" /> New Round
              </button>
            </div>
          </div>
        </main>
      </div>
    </Layouts.app>
    """
  end
end
