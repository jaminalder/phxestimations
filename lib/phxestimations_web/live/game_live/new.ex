defmodule PhxestimationsWeb.GameLive.New do
  use PhxestimationsWeb, :live_view

  alias Phxestimations.Poker
  alias PhxestimationsWeb.Plugs.ParticipantSession

  @impl true
  def mount(_params, session, socket) do
    participant_id = ParticipantSession.get_participant_id(session)
    saved_name = ParticipantSession.get_participant_name(session) || ""

    deck_types =
      Poker.deck_types()
      |> Enum.map(fn type -> {Poker.deck_display_name(type), type} end)

    default_game_name = Poker.generate_game_name()
    default_player_name = Poker.generate_player_name()

    {:ok,
     assign(socket,
       page_title: "New Game",
       participant_id: participant_id,
       form:
         to_form(%{
           "name" => "",
           "deck_type" => "fibonacci",
           "player_name" => saved_name,
           "role" => "voter"
         }),
       deck_types: deck_types,
       default_game_name: default_game_name,
       default_player_name: default_player_name,
       selected_avatar: Enum.random(Poker.avatar_ids()),
       available_avatars: Poker.avatar_ids()
     )}
  end

  @impl true
  def handle_event("select_avatar", %{"avatar-id" => avatar_id_str}, socket) do
    avatar_id = String.to_integer(avatar_id_str)
    {:noreply, assign(socket, :selected_avatar, avatar_id)}
  end

  @impl true
  def handle_event(
        "create_game",
        %{"name" => name, "deck_type" => deck_type, "player_name" => player_name, "role" => role},
        socket
      ) do
    player_name = String.trim(player_name)
    player_name = if player_name == "", do: socket.assigns.default_player_name, else: player_name

    deck_type_atom =
      case deck_type do
        "fibonacci" -> :fibonacci
        "tshirt" -> :tshirt
      end

    role_atom =
      case role do
        "voter" -> :voter
        "spectator" -> :spectator
      end

    avatar_id = socket.assigns.selected_avatar

    with {:ok, game_id} <- Poker.create_game(name, deck_type_atom),
         {:ok, _game} <-
           Poker.join_game(
             game_id,
             socket.assigns.participant_id,
             player_name,
             role_atom,
             avatar_id
           ) do
      {:noreply,
       socket
       |> put_flash(:info, "Game created successfully!")
       |> push_navigate(to: "/games/#{game_id}?name=#{URI.encode(player_name)}")}
    else
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create game. Please try again.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="new-game-page" class="min-h-screen flex flex-col items-center justify-center px-4">
        <div class="w-full max-w-md">
          <.link
            navigate={~p"/"}
            class="inline-flex items-center gap-2 text-slate-400 hover:text-white transition-colors mb-8"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to home
          </.link>

          <div class="bg-slate-800/50 border border-slate-700/50 rounded-2xl p-8">
            <div class="text-center mb-8">
              <div class="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 shadow-lg shadow-blue-500/25 mb-4">
                <.icon name="hero-plus" class="w-7 h-7 text-white" />
              </div>
              <h1 class="text-2xl font-bold text-white" style="font-family: var(--font-display);">
                Create New Game
              </h1>
              <p class="text-slate-400 mt-2">
                Set up your session and jump right in
              </p>
            </div>

            <.form
              id="new-game-form"
              for={@form}
              phx-submit="create_game"
              class="space-y-6"
            >
              <div>
                <label for="game-name" class="block text-sm font-medium text-slate-300 mb-2">
                  Game Name <span class="text-slate-500 font-normal">(optional)</span>
                </label>
                <input
                  type="text"
                  id="game-name"
                  name="name"
                  value={@form[:name].value}
                  placeholder={@default_game_name}
                  class={[
                    "w-full px-4 py-3 rounded-xl",
                    "bg-slate-900/50 border border-slate-600/50",
                    "text-white placeholder-slate-500",
                    "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent",
                    "transition-all duration-150"
                  ]}
                />
              </div>

              <div>
                <label for="deck-type" class="block text-sm font-medium text-slate-300 mb-2">
                  Voting System
                </label>
                <div class="relative">
                  <select
                    id="deck-type"
                    name="deck_type"
                    class={[
                      "w-full px-4 py-3 rounded-xl appearance-none",
                      "bg-slate-900/50 border border-slate-600/50",
                      "text-white",
                      "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent",
                      "transition-all duration-150 cursor-pointer"
                    ]}
                  >
                    <%= for {label, value} <- @deck_types do %>
                      <option value={value} selected={@form[:deck_type].value == to_string(value)}>
                        {label}
                      </option>
                    <% end %>
                  </select>
                  <div class="absolute inset-y-0 right-0 flex items-center pr-4 pointer-events-none">
                    <.icon name="hero-chevron-down" class="w-5 h-5 text-slate-400" />
                  </div>
                </div>
              </div>

              <div>
                <label for="player-name" class="block text-sm font-medium text-slate-300 mb-2">
                  Your Name <span class="text-slate-500 font-normal">(optional)</span>
                </label>
                <input
                  type="text"
                  id="player-name"
                  name="player_name"
                  value={@form[:player_name].value}
                  placeholder={@default_player_name}
                  autofocus
                  class={[
                    "w-full px-4 py-3 rounded-xl",
                    "bg-slate-900/50 border border-slate-600/50",
                    "text-white placeholder-slate-500",
                    "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent",
                    "transition-all duration-150"
                  ]}
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-slate-300 mb-3">
                  Choose Your Avatar
                </label>
                <PhxestimationsWeb.GameComponents.avatar_selector
                  selected_avatar={@selected_avatar}
                  available_avatars={@available_avatars}
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-slate-300 mb-3">
                  Your Role
                </label>
                <div class="grid grid-cols-2 gap-3">
                  <label class="cursor-pointer">
                    <input
                      type="radio"
                      name="role"
                      value="voter"
                      checked={@form[:role].value == "voter"}
                      class="peer sr-only"
                    />
                    <div class={[
                      "p-4 rounded-xl border-2 text-center transition-all duration-150",
                      "border-slate-600/50 bg-slate-900/30",
                      "peer-checked:border-blue-500 peer-checked:bg-blue-500/10",
                      "hover:border-slate-500"
                    ]}>
                      <div class="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center mx-auto mb-2">
                        <.icon name="hero-hand-raised" class="w-5 h-5 text-blue-400" />
                      </div>
                      <span class="font-medium text-white">Voter</span>
                      <p class="text-xs text-slate-400 mt-1">
                        Participate in voting
                      </p>
                    </div>
                  </label>

                  <label class="cursor-pointer">
                    <input
                      type="radio"
                      name="role"
                      value="spectator"
                      checked={@form[:role].value == "spectator"}
                      class="peer sr-only"
                    />
                    <div class={[
                      "p-4 rounded-xl border-2 text-center transition-all duration-150",
                      "border-slate-600/50 bg-slate-900/30",
                      "peer-checked:border-purple-500 peer-checked:bg-purple-500/10",
                      "hover:border-slate-500"
                    ]}>
                      <div class="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center mx-auto mb-2">
                        <.icon name="hero-eye" class="w-5 h-5 text-purple-400" />
                      </div>
                      <span class="font-medium text-white">Spectator</span>
                      <p class="text-xs text-slate-400 mt-1">
                        Watch without voting
                      </p>
                    </div>
                  </label>
                </div>
              </div>

              <div class="pt-4">
                <button
                  id="create-game-btn"
                  type="submit"
                  class={[
                    "w-full inline-flex items-center justify-center gap-2 px-6 py-4 rounded-xl",
                    "bg-blue-500 hover:bg-blue-400 text-white font-semibold text-lg",
                    "shadow-lg shadow-blue-500/25 hover:shadow-xl hover:shadow-blue-500/30",
                    "transition-all duration-150 hover:-translate-y-0.5",
                    "focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2 focus:ring-offset-slate-800"
                  ]}
                >
                  <.icon name="hero-rocket-launch" class="w-5 h-5" /> Create & Join
                </button>
              </div>
            </.form>
          </div>

          <div class="mt-8 text-center">
            <p class="text-sm text-slate-500">
              Your team can join using the invite link once you're in
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
