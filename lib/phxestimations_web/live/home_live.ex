defmodule PhxestimationsWeb.HomeLive do
  use PhxestimationsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="home-page" class="min-h-screen flex flex-col items-center justify-center px-4">
        <div class="text-center max-w-2xl mx-auto">
          <div class="mb-8">
            <div class="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-gradient-to-br from-blue-500 to-blue-600 shadow-lg shadow-blue-500/25 mb-6">
              <.icon name="hero-rocket-launch" class="w-10 h-10 text-white" />
            </div>
            <h1
              class="text-4xl md:text-5xl font-bold text-white mb-4"
              style="font-family: var(--font-display);"
            >
              Planning Poker
            </h1>
            <p class="text-lg md:text-xl text-slate-400 max-w-md mx-auto">
              Easy-to-use estimation for agile teams. No signup required.
            </p>
          </div>

          <.link
            id="start-game-btn"
            navigate={~p"/games/new"}
            class={[
              "inline-flex items-center gap-2 px-8 py-4 rounded-xl",
              "bg-blue-500 hover:bg-blue-400 text-white font-semibold text-lg",
              "shadow-lg shadow-blue-500/25 hover:shadow-xl hover:shadow-blue-500/30",
              "transition-all duration-150 hover:-translate-y-0.5",
              "focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2 focus:ring-offset-slate-900"
            ]}
          >
            <.icon name="hero-plus" class="w-5 h-5" /> Start New Game
          </.link>

          <div class="mt-16 grid grid-cols-1 md:grid-cols-3 gap-6 text-left">
            <div class="p-6 rounded-xl bg-slate-800/50 border border-slate-700/50">
              <div class="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center mb-4">
                <.icon name="hero-bolt" class="w-5 h-5 text-emerald-400" />
              </div>
              <h3 class="font-semibold text-white mb-2">Real-time</h3>
              <p class="text-sm text-slate-400">
                See votes appear instantly as your team estimates together.
              </p>
            </div>

            <div class="p-6 rounded-xl bg-slate-800/50 border border-slate-700/50">
              <div class="w-10 h-10 rounded-lg bg-purple-500/10 flex items-center justify-center mb-4">
                <.icon name="hero-link" class="w-5 h-5 text-purple-400" />
              </div>
              <h3 class="font-semibold text-white mb-2">Just Share a Link</h3>
              <p class="text-sm text-slate-400">
                No accounts needed. Share a link and start estimating in seconds.
              </p>
            </div>

            <div class="p-6 rounded-xl bg-slate-800/50 border border-slate-700/50">
              <div class="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center mb-4">
                <.icon name="hero-eye" class="w-5 h-5 text-amber-400" />
              </div>
              <h3 class="font-semibold text-white mb-2">Spectator Mode</h3>
              <p class="text-sm text-slate-400">
                Product owners can watch without influencing estimates.
              </p>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
