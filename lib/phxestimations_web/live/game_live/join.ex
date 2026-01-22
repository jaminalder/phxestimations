defmodule PhxestimationsWeb.GameLive.Join do
  use PhxestimationsWeb, :live_view

  alias Phxestimations.Poker
  alias PhxestimationsWeb.Plugs.ParticipantSession

  @impl true
  def mount(%{"id" => game_id}, session, socket) do
    case Poker.get_game(game_id) do
      {:ok, game} ->
        participant_id = ParticipantSession.get_participant_id(session)
        saved_name = ParticipantSession.get_participant_name(session) || ""

        {:ok,
         assign(socket,
           page_title: "Join #{game.name}",
           game_id: game_id,
           game: game,
           participant_id: participant_id,
           form: to_form(%{"name" => saved_name, "role" => "voter"})
         )}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("join_game", %{"name" => name, "role" => role}, socket) do
    name = String.trim(name)

    if name == "" do
      {:noreply, put_flash(socket, :error, "Please enter your name")}
    else
      role_atom = String.to_existing_atom(role)

      case Poker.join_game(
             socket.assigns.game_id,
             socket.assigns.participant_id,
             name,
             role_atom
           ) do
        {:ok, _game} ->
          {:noreply,
           socket
           |> push_navigate(to: "/games/#{socket.assigns.game_id}?name=#{URI.encode(name)}")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Failed to join game. Please try again.")}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="join-game-page" class="min-h-screen flex flex-col items-center justify-center px-4">
        <div class="w-full max-w-md">
          <.link
            navigate={~p"/"}
            class="inline-flex items-center gap-2 text-slate-400 hover:text-white transition-colors mb-8"
          >
            <.icon name="hero-arrow-left" class="w-4 h-4" /> Back to home
          </.link>

          <div class="bg-slate-800/50 border border-slate-700/50 rounded-2xl p-8">
            <div class="text-center mb-8">
              <div class="inline-flex items-center justify-center w-14 h-14 rounded-xl bg-gradient-to-br from-emerald-500 to-emerald-600 shadow-lg shadow-emerald-500/25 mb-4">
                <.icon name="hero-user-plus" class="w-7 h-7 text-white" />
              </div>
              <h1 class="text-2xl font-bold text-white" style="font-family: var(--font-display);">
                Join Game
              </h1>
              <p class="text-slate-400 mt-2">
                {@game.name}
              </p>
              <p class="text-sm text-slate-500 mt-1">
                {Poker.deck_display_name(@game.deck_type)} deck
              </p>
            </div>

            <.form id="join-game-form" for={@form} phx-submit="join_game" class="space-y-6">
              <div>
                <label for="participant-name" class="block text-sm font-medium text-slate-300 mb-2">
                  Your Name
                </label>
                <input
                  type="text"
                  id="participant-name"
                  name="name"
                  value={@form[:name].value}
                  placeholder="Enter your name..."
                  autofocus
                  class={[
                    "w-full px-4 py-3 rounded-xl",
                    "bg-slate-900/50 border border-slate-600/50",
                    "text-white placeholder-slate-500",
                    "focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent",
                    "transition-all duration-150"
                  ]}
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
                      "peer-checked:border-emerald-500 peer-checked:bg-emerald-500/10",
                      "hover:border-slate-500"
                    ]}>
                      <div class="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center mx-auto mb-2 peer-checked:bg-emerald-500/20">
                        <.icon name="hero-hand-raised" class="w-5 h-5 text-emerald-400" />
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
                      <div class="w-10 h-10 rounded-lg bg-slate-800 flex items-center justify-center mx-auto mb-2 peer-checked:bg-purple-500/20">
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
                  id="join-btn"
                  type="submit"
                  class={[
                    "w-full inline-flex items-center justify-center gap-2 px-6 py-4 rounded-xl",
                    "bg-emerald-500 hover:bg-emerald-400 text-white font-semibold text-lg",
                    "shadow-lg shadow-emerald-500/25 hover:shadow-xl hover:shadow-emerald-500/30",
                    "transition-all duration-150 hover:-translate-y-0.5",
                    "focus:outline-none focus:ring-2 focus:ring-emerald-400 focus:ring-offset-2 focus:ring-offset-slate-800"
                  ]}
                >
                  <.icon name="hero-arrow-right-circle" class="w-5 h-5" /> Join Game
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
