defmodule PhxestimationsWeb.GameLive.New do
  use PhxestimationsWeb, :live_view

  alias Phxestimations.Poker

  @impl true
  def mount(_params, _session, socket) do
    deck_types =
      Poker.deck_types()
      |> Enum.map(fn type -> {Poker.deck_display_name(type), type} end)

    {:ok,
     assign(socket,
       page_title: "New Game",
       form: to_form(%{"name" => "", "deck_type" => "fibonacci"}),
       deck_types: deck_types
     )}
  end

  @impl true
  def handle_event("create_game", %{"name" => name, "deck_type" => deck_type}, socket) do
    deck_type_atom = String.to_existing_atom(deck_type)

    case Poker.create_game(name, deck_type_atom) do
      {:ok, game_id} ->
        {:noreply,
         socket
         |> put_flash(:info, "Game created successfully!")
         |> push_navigate(to: ~p"/games/#{game_id}/join")}

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
                Set up your planning poker session
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
                  placeholder="e.g., Sprint Planning, Backlog Refinement..."
                  class={[
                    "w-full px-4 py-3 rounded-xl",
                    "bg-slate-900/50 border border-slate-600/50",
                    "text-white placeholder-slate-500",
                    "focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent",
                    "transition-all duration-150"
                  ]}
                />
                <p class="mt-2 text-sm text-slate-500">
                  Leave empty for an auto-generated name
                </p>
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
                  <.icon name="hero-rocket-launch" class="w-5 h-5" /> Create Game
                </button>
              </div>
            </.form>
          </div>

          <div class="mt-8 text-center">
            <p class="text-sm text-slate-500">
              After creating, you'll get a link to share with your team
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
