defmodule PhxestimationsWeb.GameComponents do
  @moduledoc """
  Provides game-specific UI components for the Planning Poker application.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Phxestimations.Poker
  alias Phxestimations.Poker.Deck

  # ============================================================================
  # Avatar Components
  # ============================================================================

  @doc """
  Renders a Dicebear bottts avatar image.

  ## Sizes
    - `:sm` - 32x32 (8)
    - `:md` - 48x48 (12) - default
    - `:lg` - 64x64 (16)

  ## Examples

      <.avatar avatar_id={1} />
      <.avatar avatar_id={3} size={:lg} />
  """
  attr :avatar_id, :integer, required: true
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :class, :string, default: ""

  def avatar(assigns) do
    size_class =
      case assigns.size do
        :sm -> "w-8 h-8"
        :md -> "w-12 h-12"
        :lg -> "w-16 h-16"
      end

    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <img
      src={Poker.avatar_url(@avatar_id)}
      alt="Avatar"
      class={["rounded-full bg-slate-700", @size_class, @class]}
    />
    """
  end

  @doc """
  Renders an avatar selector showing all available avatars.

  Displays 7 avatars in a row with visual indicators for availability and selection.

  ## Examples

      <.avatar_selector
        selected_avatar={3}
        available_avatars={[1, 2, 3, 5, 7]}
        on_select="select_avatar"
      />
  """
  attr :selected_avatar, :integer, default: nil
  attr :available_avatars, :list, required: true
  attr :on_select, :string, default: "select_avatar"

  def avatar_selector(assigns) do
    all_ids = Poker.avatar_ids()
    assigns = assign(assigns, :all_ids, all_ids)

    ~H"""
    <div class="flex flex-wrap justify-center gap-3">
      <%= for id <- @all_ids do %>
        <% available? = id in @available_avatars %>
        <% selected? = @selected_avatar == id %>
        <button
          id={"avatar-#{id}"}
          type="button"
          phx-click={@on_select}
          phx-value-avatar-id={id}
          disabled={!available?}
          class={[
            "relative p-1 rounded-full transition-all duration-150",
            "focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-offset-2 focus:ring-offset-slate-800",
            cond do
              selected? ->
                "ring-2 ring-blue-500 ring-offset-2 ring-offset-slate-800"

              !available? ->
                "opacity-40 cursor-not-allowed"

              true ->
                "hover:scale-110 cursor-pointer"
            end
          ]}
        >
          <.avatar avatar_id={id} size={:md} />
          <div
            :if={!available?}
            class="absolute inset-0 flex items-center justify-center bg-slate-900/60 rounded-full"
          >
            <span class="text-xs text-slate-400 font-medium">Taken</span>
          </div>
          <div
            :if={selected?}
            class="absolute -bottom-1 -right-1 w-5 h-5 bg-blue-500 rounded-full flex items-center justify-center"
          >
            <span class="hero-check w-3 h-3 text-white"></span>
          </div>
        </button>
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # Card Components
  # ============================================================================

  @doc """
  Renders a poker card that can be selected for voting.

  Special cards (?, coffee, infinity, bug) display icons instead of text.

  ## Examples

      <.poker_card card="5" selected={true} disabled={false} />
  """
  attr :card, :string, required: true
  attr :selected, :boolean, default: false
  attr :disabled, :boolean, default: false

  def poker_card(assigns) do
    icon = Deck.card_icon(assigns.card)
    assigns = assign(assigns, :icon, icon)

    ~H"""
    <button
      id={"card-#{@card}"}
      phx-click={unless @disabled, do: "vote"}
      phx-value-card={@card}
      disabled={@disabled}
      class={[
        "w-14 h-20 rounded-lg font-bold text-lg flex items-center justify-center",
        "transition-all duration-150",
        "focus:outline-none focus:ring-2 focus:ring-blue-400",
        if(@disabled, do: "opacity-50 cursor-not-allowed"),
        if(@selected,
          do:
            "bg-gradient-to-br from-blue-500 to-blue-600 text-white shadow-lg shadow-blue-500/25 -translate-y-1",
          else: "bg-slate-700/50 hover:bg-slate-600/50 text-white border border-slate-600/50"
        ),
        unless(@disabled, do: "hover:-translate-y-1")
      ]}
    >
      <.card_value card={@card} icon={@icon} />
    </button>
    """
  end

  @doc """
  Renders the value content for a card, with icon support for special cards.
  """
  attr :card, :string, required: true
  attr :icon, :any, default: nil
  attr :class, :string, default: "w-6 h-6"

  def card_value(assigns) do
    ~H"""
    <%= case @icon do %>
      <% :infinity -> %>
        <svg class={@class} viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M18.178 8c5.096 0 5.096 8 0 8-5.095 0-7.133-8-12.739-8-4.585 0-4.585 8 0 8 5.606 0 7.644-8 12.74-8z" />
        </svg>
      <% nil -> %>
        {@card}
      <% icon -> %>
        <span class={[icon, @class]}></span>
    <% end %>
    """
  end

  @doc """
  Renders the card selection deck.

  ## Examples

      <.card_deck cards={["1", "2", "3"]} selected_card="2" state={:voting} />
  """
  attr :cards, :list, required: true
  attr :selected_card, :string, default: nil
  attr :state, :atom, required: true

  def card_deck(assigns) do
    ~H"""
    <div id="card-deck" class="border-t border-slate-700/50 bg-slate-800/30 backdrop-blur-sm p-6">
      <div class="max-w-4xl mx-auto">
        <div :if={@state == :voting} class="flex flex-wrap justify-center gap-2">
          <.poker_card
            :for={card <- @cards}
            card={card}
            selected={@selected_card == card}
            disabled={false}
          />
        </div>
        <div :if={@state == :revealed} class="text-center text-slate-400">
          Votes have been revealed. Start a new round to vote again.
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a participant's card on the poker table.

  Shows the participant's avatar with a card overlay indicator at the bottom-right.

  ## Examples

      <.participant_card participant={participant} current_user?={true} revealed?={false} />
  """
  attr :participant, :map, required: true
  attr :current_user?, :boolean, default: false
  attr :revealed?, :boolean, default: false

  def participant_card(assigns) do
    icon =
      if assigns.revealed? && assigns.participant.vote do
        Deck.card_icon(assigns.participant.vote)
      else
        nil
      end

    assigns = assign(assigns, :vote_icon, icon)

    ~H"""
    <div
      id={"participant-#{@participant.id}"}
      class={[
        "p-4 rounded-xl animate-fade-in-up",
        "bg-slate-800/50 border-2",
        if(@current_user?, do: "border-blue-500", else: "border-slate-700/50"),
        if(!@participant.connected, do: "opacity-50")
      ]}
    >
      <p class={[
        "text-sm font-medium truncate mb-3",
        if(@participant.connected, do: "text-white", else: "text-slate-500")
      ]}>
        {@participant.name}
      </p>
      <p :if={!@participant.connected} class="text-xs text-slate-500 -mt-2 mb-2">disconnected</p>

      <div class="flex items-center gap-3">
        <div class="shrink-0">
          <%= if @participant.avatar_id do %>
            <.avatar avatar_id={@participant.avatar_id} size={:lg} />
          <% else %>
            <div class="w-16 h-16 rounded-full bg-gradient-to-br from-slate-600 to-slate-700 flex items-center justify-center text-2xl font-bold text-white">
              {String.first(@participant.name) |> String.upcase()}
            </div>
          <% end %>
        </div>

        <div
          id={"participant-#{@participant.id}-card"}
          class={[
            "w-12 h-16 rounded-lg flex items-center justify-center",
            "text-sm font-bold shadow-lg",
            cond do
              @revealed? && @participant.vote ->
                "bg-gradient-to-br from-emerald-500 to-emerald-600 text-white"

              @participant.vote ->
                "bg-gradient-to-br from-blue-500 to-blue-600 text-white"

              true ->
                "bg-slate-700 border border-slate-600 text-slate-400"
            end
          ]}
        >
          <%= if @revealed? && @participant.vote do %>
            <.card_value card={@participant.vote} icon={@vote_icon} class="w-5 h-5" />
          <% else %>
            <%= if @participant.vote do %>
              <span class="hero-check w-5 h-5"></span>
            <% else %>
              ?
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the voting status indicator.

  ## Examples

      <.voting_status state={:voting} vote_count={3} total_voters={5} />
  """
  attr :state, :atom, required: true
  attr :vote_count, :integer, default: 0
  attr :total_voters, :integer, default: 0
  attr :statistics, :map, default: nil

  def voting_status(assigns) do
    ~H"""
    <div class="text-center mb-8">
      <div :if={@state == :voting} class="space-y-2">
        <p class="text-slate-400">
          <span class="text-2xl font-bold text-white">{@vote_count}</span>
          <span class="text-slate-500">/ {@total_voters}</span> voted
        </p>
        <div class="flex items-center justify-center gap-2">
          <div class="h-2 rounded-full bg-slate-700 w-48 overflow-hidden">
            <div
              class="h-full bg-gradient-to-r from-blue-500 to-emerald-500 transition-all duration-300"
              style={"width: #{if @total_voters > 0, do: @vote_count / @total_voters * 100, else: 0}%"}
            />
          </div>
        </div>
      </div>
      <div :if={@state == :revealed} class="space-y-4">
        <p class="text-lg font-semibold text-emerald-400">Votes Revealed!</p>
        <.vote_statistics :if={@statistics} statistics={@statistics} />
      </div>
    </div>
    """
  end

  @doc """
  Renders vote statistics after reveal.
  """
  attr :statistics, :map, required: true

  def vote_statistics(assigns) do
    ~H"""
    <div id="vote-statistics">
      <div :if={@statistics.average} id="vote-average" class="text-center">
        <span class="text-sm text-slate-400">Average:</span>
        <span class="text-2xl font-bold text-white ml-2">
          {Float.round(@statistics.average, 1)}
        </span>
      </div>
    </div>
    """
  end

  @doc """
  Renders the game control buttons (reveal/reset).

  ## Examples

      <.game_controls state={:voting} all_voted?={true} />
  """
  attr :state, :atom, required: true
  attr :all_voted?, :boolean, default: false

  def game_controls(assigns) do
    ~H"""
    <div class="border-t border-slate-700/50 bg-slate-900/50 p-4">
      <div class="max-w-4xl mx-auto flex items-center justify-center gap-4">
        <button
          :if={@state == :voting}
          id="reveal-btn"
          phx-click="reveal"
          disabled={!@all_voted?}
          class={[
            "inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold",
            "transition-all duration-150",
            if(@all_voted?,
              do: "bg-emerald-500 hover:bg-emerald-400 text-white shadow-lg shadow-emerald-500/25",
              else: "bg-slate-700 text-slate-400 cursor-not-allowed"
            )
          ]}
        >
          <span class="hero-eye w-5 h-5"></span> Reveal Votes
        </button>

        <button
          :if={@state == :revealed}
          id="reset-btn"
          phx-click="reset"
          class={[
            "inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold",
            "bg-blue-500 hover:bg-blue-400 text-white",
            "shadow-lg shadow-blue-500/25",
            "transition-all duration-150"
          ]}
        >
          <span class="hero-arrow-path w-5 h-5"></span> New Round
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders the invite modal.

  ## Examples

      <.invite_modal game_url="https://example.com/games/abc123" />
  """
  attr :game_url, :string, required: true
  attr :show, :boolean, default: false

  def invite_modal(assigns) do
    ~H"""
    <div
      :if={@show}
      id="invite-modal"
      class="fixed inset-0 z-50 flex items-center justify-center"
      phx-mounted={JS.transition({"ease-out duration-200", "opacity-0", "opacity-100"})}
    >
      <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" phx-click="close_invite"></div>

      <div class="relative bg-slate-800 border border-slate-700 rounded-2xl p-6 max-w-md w-full mx-4 shadow-2xl">
        <button
          id="close-invite-btn"
          type="button"
          phx-click="close_invite"
          class="absolute top-4 right-4 text-slate-400 hover:text-white"
        >
          <span class="hero-x-mark w-6 h-6"></span>
        </button>

        <div class="text-center mb-6">
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-blue-500/10 mb-4">
            <span class="hero-link w-6 h-6 text-blue-400"></span>
          </div>
          <h2 class="text-xl font-bold text-white">Invite Team Members</h2>
          <p class="text-sm text-slate-400 mt-1">Share this link to invite others to join</p>
        </div>

        <div class="space-y-4">
          <div class="flex gap-2">
            <input
              type="text"
              id="invite-link"
              value={@game_url}
              readonly
              class="flex-1 px-4 py-3 rounded-xl bg-slate-900/50 border border-slate-600/50 text-white text-sm"
            />
            <button
              id="copy-link-btn"
              type="button"
              phx-click={JS.dispatch("phx:copy", to: "#invite-link")}
              class="px-4 py-3 rounded-xl bg-blue-500 hover:bg-blue-400 text-white font-medium transition-all"
            >
              Copy
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the game header with title and controls.
  """
  attr :game, :map, required: true

  def game_header(assigns) do
    ~H"""
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
              phx-click="show_invite"
              class={[
                "inline-flex items-center gap-2 px-4 py-2 rounded-lg",
                "bg-slate-700/50 hover:bg-slate-600/50 text-slate-300 hover:text-white",
                "border border-slate-600/50",
                "transition-all duration-150"
              ]}
            >
              <span class="hero-link w-4 h-4"></span> Invite
            </button>
          </div>
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Renders the poker table with all participants.
  """
  attr :voters, :list, required: true
  attr :spectators, :list, required: true
  attr :current_participant_id, :string, required: true
  attr :game_state, :atom, required: true
  attr :vote_count, :integer, required: true
  attr :total_voters, :integer, required: true
  attr :statistics, :map, default: nil

  def poker_table(assigns) do
    ~H"""
    <div id="poker-table" class="flex-1 flex items-center justify-center p-8">
      <div class="w-full max-w-4xl">
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 mb-8">
          <.participant_card
            :for={voter <- @voters}
            participant={voter}
            current_user?={voter.id == @current_participant_id}
            revealed?={@game_state == :revealed}
          />
        </div>

        <.voting_status
          state={@game_state}
          vote_count={@vote_count}
          total_voters={@total_voters}
          statistics={@statistics}
        />

        <div :if={@spectators != []} class="text-center text-sm text-slate-500 mt-6">
          <span class="hero-eye w-4 h-4 inline"></span>
          <span class="ml-1">
            Spectators: {Enum.map(@spectators, & &1.name) |> Enum.join(", ")}
          </span>
        </div>
      </div>
    </div>
    """
  end
end
