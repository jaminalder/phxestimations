# Planning Poker - Claude Context

A real-time Scrum Planning Poker application built with Phoenix LiveView.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `mix setup` | Install deps, setup and build assets |
| `mix phx.server` | Start dev server at localhost:4000 |
| `mix test` | Run tests |
| `mix test --stale` | Run only tests affected by changes |
| `mix precommit` | **Required before finishing** - compile, format, test |
| `mix format` | Format all code |
| `mix smoke_test` | Quick API-level smoke tests (no ExUnit) |
| `mix test test/phxestimations_web/integration/` | Multi-user integration tests |

## Documentation Map

| Document | Purpose |
|----------|---------|
| [REQUIREMENTS.md](./REQUIREMENTS.md) | Product requirements, features, user flows |
| [AGENTS.md](./AGENTS.md) | Workflow rules, verification, architecture |
| [PHOENIX_INSTRUCTIONS.md](./PHOENIX_INSTRUCTIONS.md) | Technical guidelines, Phoenix/LiveView patterns |

## Application Overview

**What**: Planning poker for agile teams - no database, no auth, real-time via LiveView.

**Key Decisions**:
- Card decks: Fibonacci + T-Shirt sizes
- Anyone can reveal/start voting
- Spectator mode supported
- Optional story names
- Dark theme only
- In-memory state (GenServer per game)

## Architecture

```
lib/
  phxestimations/           # Business logic (pure Elixir)
    game.ex                 # Game state management
    game_server.ex          # GenServer for game processes
    ...
  phxestimations_web/       # Web layer
    live/                   # LiveViews (thin UI layer)
    components/             # Reusable components
    ...
```

**Rules**:
- LiveViews own UI state only
- Business logic in plain Elixir modules
- No Ecto/database
- No authentication
- State managed via GenServer + PubSub

---

## AI Agent Tooling

### Console Module

Interactive game manipulation from IEx (`iex -S mix phx.server`):

```elixir
alias Phxestimations.Dev.Console, as: C
C.demo()            # Full 2-round demo
C.quick_game(3)     # Create game + 3 voters
C.list_games()      # List all active games
C.inspect_game(id)  # Pretty-print game state
```

See `lib/phxestimations/dev/console.ex` for full API.

### Test Helpers (GameHelpers)

`test/support/game_helpers.ex` — auto-imported in ConnCase. Provides:
- `build_user_conn/0`, `setup_game_with_voters/2`, `setup_game_with_mixed/3`
- `vote_via_view/2`, `reveal_via_view/1`, `reset_via_view/1`
- `assert_voting_state/1`, `assert_revealed_state/1`, `assert_average_displayed/2`

### Integration Tests

`test/phxestimations_web/integration/` — multi-user LiveView tests covering game lifecycle, voting, spectators, stories, invites, edge cases, and deck types.

---

## UI Design Guidelines

### Design Direction: "Midnight Focus"

A refined, dark interface optimized for concentration during estimation sessions. The aesthetic combines the clarity of a well-designed productivity tool with subtle depth and atmosphere.

### Color Palette

```css
/* Primary palette - deep blues */
--bg-primary: #0f1419;       /* Near-black base */
--bg-secondary: #1a2332;     /* Card/panel backgrounds */
--bg-elevated: #243044;      /* Hover states, modals */
--bg-interactive: #2d4a6f;   /* Buttons, selected states */

/* Accent - electric blue */
--accent-primary: #3b82f6;   /* Primary actions */
--accent-glow: #60a5fa;      /* Hover/active states */
--accent-subtle: rgba(59, 130, 246, 0.15); /* Backgrounds */

/* Text hierarchy */
--text-primary: #f1f5f9;     /* Primary text */
--text-secondary: #94a3b8;   /* Secondary/muted */
--text-tertiary: #64748b;    /* Disabled/hints */

/* Status colors */
--success: #22c55e;          /* Voted, consensus */
--warning: #eab308;          /* Attention needed */
--error: #ef4444;            /* Errors */
```

### Typography

Use a distinctive, modern font pairing:
- **Headlines**: "Space Mono" or "JetBrains Mono" - monospace for that technical feel
- **Body**: "Plus Jakarta Sans" or "DM Sans" - clean, highly readable
- **Card values**: Large, bold numerics - make them unmistakable

Import via CSS:
```css
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Space+Mono:wght@700&display=swap');
```

### Card Design

Cards are the hero element. Make them memorable:
- **Face-down**: Subtle diagonal pattern, slight glow when voted
- **Face-up**: Clean value display, color-coded by range
- **Selected**: Elevated with accent border glow
- **Animations**: Smooth flip transitions (0.4s ease-out)

```css
/* Card flip animation */
.card {
  transform-style: preserve-3d;
  transition: transform 0.4s ease-out;
}
.card.flipped {
  transform: rotateY(180deg);
}
```

### Spatial Layout

- Participants arranged in an oval/table formation
- Central action area (table) with generous padding
- Card deck fixed at bottom, horizontally scrollable on mobile
- Asymmetric spacing creates visual interest

### Motion & Micro-interactions

- **Page load**: Staggered fade-in for participants (animation-delay: 0.05s each)
- **Vote cast**: Card lifts slightly, subtle pulse
- **Reveal**: Cards flip sequentially around the table
- **Hover states**: Subtle scale (1.02) and glow
- **Button clicks**: Quick scale down (0.98) then back

### Key UI Principles

1. **Usability first**: Large touch targets (min 44px), clear visual hierarchy
2. **Instant feedback**: Every action has visible response within 100ms
3. **Minimal chrome**: Hide non-essential UI, focus on the game
4. **Spatial memory**: Keep elements in consistent positions
5. **Progressive disclosure**: Show stats only after reveal

### Component Patterns

**Buttons**:
```html
<button class="px-6 py-3 bg-blue-500 hover:bg-blue-400
               rounded-lg font-medium transition-all duration-150
               hover:shadow-lg hover:shadow-blue-500/25
               active:scale-98">
```

**Cards (poker)**:
```html
<div class="w-16 h-24 rounded-xl bg-gradient-to-br from-slate-700 to-slate-800
            shadow-lg border border-slate-600/50
            flex items-center justify-center
            text-2xl font-bold text-white">
```

**Participant avatar**:
```html
<div class="flex flex-col items-center gap-2">
  <div class="w-12 h-12 rounded-full bg-gradient-to-br from-blue-400 to-blue-600
              flex items-center justify-center text-white font-bold">
    <!-- Initial or icon -->
  </div>
  <span class="text-sm text-slate-300">Name</span>
</div>
```

### Accessibility

- WCAG AA contrast ratios minimum
- Focus indicators on all interactive elements
- Keyboard navigation support
- Screen reader announcements for state changes

---

## Critical Reminders

### LiveView Patterns
- Wrap templates with `<Layouts.app flash={@flash}>`
- Use `<.input>` component for forms
- Use `<.icon name="hero-*">` for icons
- Forms must use `to_form/2` - never access changesets in templates
- Streams for collections: `stream(socket, :items, items)` + `phx-update="stream"`

### Testing
- Every interactive element needs a stable DOM ID
- Use `has_element?/2` not raw HTML assertions
- `mix test --failed` to re-run failures

### Definition of Done
- `mix precommit` passes
- All new UI has automated tests
- Stable DOM IDs on key elements
- No new dependencies without explicit request

---

## File Locations

| What | Where |
|------|-------|
| LiveViews | `lib/phxestimations_web/live/` |
| Components | `lib/phxestimations_web/components/` |
| Business logic | `lib/phxestimations/` |
| Tests | `test/` |
| CSS | `assets/css/app.css` |
| JS | `assets/js/app.js` |
| Static assets | `priv/static/` |

---

## CSS/Styling Notes

**Current setup**:
- Tailwind v4 with new `@import "tailwindcss"` syntax
- daisyUI included but **prefer custom Tailwind components** for unique design
- Dark theme already defined with daisyUI theme plugin
- LiveView loading variants available: `phx-click-loading:`, `phx-submit-loading:`

**For dark-only theme**: Set `data-theme="dark"` on `<html>` element in `root.html.heex`

**Custom fonts**: Add to `assets/css/app.css`:
```css
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Space+Mono:wght@700&display=swap');

@theme {
  --font-display: "Space Mono", monospace;
  --font-body: "Plus Jakarta Sans", sans-serif;
}
```
