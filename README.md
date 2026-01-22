# Planning Poker

A lightweight, real-time Scrum Planning Poker application built with Elixir Phoenix LiveView.

## Features

- Real-time voting with instant updates
- No account required - just enter your name
- Shareable game links
- Fibonacci and T-Shirt size card decks
- Spectator mode
- Clean, dark-themed UI

## Quick Start

```bash
# Install dependencies and build assets
mix setup

# Start the server
mix phx.server
```

Visit [localhost:4000](http://localhost:4000)

## Development

```bash
mix test              # Run tests
mix test --stale      # Run tests affected by changes
mix precommit         # Required before commits (compile, format, test)
```

## Documentation

| Document | Description |
|----------|-------------|
| [CLAUDE.md](./CLAUDE.md) | Development context, UI design guidelines |
| [REQUIREMENTS.md](./REQUIREMENTS.md) | Product requirements and specifications |
| [AGENTS.md](./AGENTS.md) | Workflow rules for autonomous agents |
| [PHOENIX_INSTRUCTIONS.md](./PHOENIX_INSTRUCTIONS.md) | Phoenix/LiveView technical guidelines |

## Tech Stack

- **Backend**: Elixir + Phoenix 1.8
- **Real-time**: Phoenix LiveView + PubSub
- **Styling**: Tailwind CSS
- **State**: In-memory (GenServer per game)
- **No database** - ephemeral sessions only
