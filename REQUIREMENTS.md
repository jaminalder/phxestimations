# Planning Poker Application - Requirements Document

## Key Decisions Summary

| Decision | Choice |
|----------|--------|
| Card Decks | Fibonacci + T-Shirt sizes |
| Who Can Control | Anyone can reveal/start new voting |
| Spectator Mode | Yes, users can join as spectator |
| Story Names | Optional, editable anytime before reveal |
| Vote Changing | Yes, can change vote before reveal |
| Game Name | Optional with auto-generation |
| Theme | Dark theme only |
| Mid-round Join | New joiners can vote immediately |
| Authentication | None - just enter display name |
| Database | None - in-memory state only |

---

## Overview
A lightweight, real-time Scrum Planning Poker application built with Elixir Phoenix LiveView. The app enables agile teams to estimate story points collaboratively without requiring user accounts or persistent data storage.

---

## Core Concepts

### Session/Game
- A unique room where team members gather to estimate stories
- Identified by a shareable URL (e.g., `/game/abc123`)
- Ephemeral - exists only while participants are connected
- Has a name (user-provided or auto-generated)
- Supports an optional story/issue name for context

### Participant
- A person in a session identified only by their display name
- No authentication required - just enter a name to join
- Two roles:
  - **Voter**: Can select cards and participate in estimation
  - **Spectator**: Can watch but does not vote (e.g., Product Owner)

### Voting Round
- One estimation at a time
- Optional story name displayed during voting
- All voters vote simultaneously (votes hidden until reveal)
- Any participant can reveal cards
- Statistics shown after reveal
- Any participant can start new voting round

---

## Functional Requirements

### FR1: Landing Page
- Clean, minimal welcome screen
- "Start new game" button prominently displayed
- Brief tagline: "Easy-to-use planning poker for agile teams"
- Dark theme aesthetic

### FR2: Create Game
- **Game name**: Optional - if blank, auto-generate a fun/random name
- **Voting system**: Dropdown to select card deck
  - Fibonacci (default): `0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, ?, coffee`
  - T-Shirt sizes: `XS, S, M, L, XL, XXL, ?, coffee`
- Click "Create game" to generate unique URL and enter room

### FR3: Join Game
- User visits shared URL (e.g., `/game/abc123`)
- If no name stored in session:
  - Show name entry form
  - Option to join as "Voter" or "Spectator"
- After entering name, join the game room
- Name persisted in browser cookie for convenience on rejoin

### FR4: Game Room - Layout
- **Header**: Game name (left), current user info (right), "Invite players" button
- **Center area**:
  - "Table" showing all participants arranged around it
  - Central action area for current state
  - Story name display (if set)
- **Bottom**: Card deck for selecting estimate (voters only)
- **Participant display**:
  - Name below each participant
  - Card showing voting status
  - Visual distinction for spectators (e.g., eye icon, different styling)

### FR5: Game Room - Voting Phase
- State: "Pick your cards!"
- Each participant shows:
  - Empty/gray card = has not voted
  - Face-down card with pattern = has voted
- Voters can:
  - Click a card to vote
  - Click a different card to change vote
  - Selected card highlighted in deck
- Spectators see the interface but have no card deck
- "Reveal cards" button appears when at least one person has voted
- Optional: Set/edit story name for current round

### FR6: Game Room - Results Phase
- State: Cards revealed
- Each participant's card flips to show their vote value
- Statistics displayed at bottom:
  - **Average**: Mean of numeric votes (excluding ?, coffee, spectators)
  - **Vote distribution**: Cards grouped by value with vote count
- "Start new voting" button to reset for next round
- Story name clears on new voting (or can be edited)

### FR7: Invite Players
- "Invite players" button in header
- Shows modal/popup with:
  - Full shareable URL
  - "Copy link" button
- Simple one-click copy functionality

### FR8: Real-time Updates
All participants see instant updates for:
- Participant joins the game
- Participant leaves/disconnects
- Participant votes (card flips to face-down)
- Participant changes vote (card stays face-down)
- Cards are revealed
- New voting round starts
- Story name is updated

### FR9: Participant Management
- Show "Feeling lonely? Invite players" prompt when alone
- Display participant count
- Handle disconnection gracefully:
  - Brief grace period before removing from game
  - Reconnecting user with same session rejoins with same name

---

## Card Deck Definitions

### Fibonacci (Default)
| Value | Type | Included in Average |
|-------|------|---------------------|
| 0 | Numeric | Yes |
| 1 | Numeric | Yes |
| 2 | Numeric | Yes |
| 3 | Numeric | Yes |
| 5 | Numeric | Yes |
| 8 | Numeric | Yes |
| 13 | Numeric | Yes |
| 21 | Numeric | Yes |
| 34 | Numeric | Yes |
| 55 | Numeric | Yes |
| 89 | Numeric | Yes |
| ? | Special | No (unsure/need discussion) |
| coffee | Special | No (need a break) |

### T-Shirt Sizes
| Value | Type | Included in Average |
|-------|------|---------------------|
| XS | Size | No (non-numeric) |
| S | Size | No |
| M | Size | No |
| L | Size | No |
| XL | Size | No |
| XXL | Size | No |
| ? | Special | No |
| coffee | Special | No |

Note: T-Shirt sizes don't have a numeric average - just show distribution.

---

## Non-Functional Requirements

### NFR1: No Database
- All game state managed in-memory via Phoenix GenServer processes
- Each game is a separate process
- Games automatically clean up when empty (after grace period)
- No persistent storage

### NFR2: No Authentication
- Users identified only by display name
- Names stored in browser cookie/session
- Same browser session reconnecting gets same identity
- No passwords, no accounts

### NFR3: Real-time Performance
- WebSocket connection via Phoenix LiveView
- Sub-second update propagation
- Graceful handling of disconnects with reconnection
- Handle network interruptions smoothly

### NFR4: Clean UI Design
- **Theme**: Dark only (dark blue/gray palette like reference)
- **Style**: Minimalist, focused, distraction-free
- **Cards**: Clean card design with clear values
- **Responsive**: Works on desktop and mobile
- **Accessibility**: Readable contrast, keyboard navigable

### NFR5: Session Management
- Game URL remains valid as long as game process is alive
- Empty games timeout after ~5 minutes of no participants
- No limit on number of participants (reasonable browser limits apply)

---

## Out of Scope

These features from the reference app are explicitly NOT included:
- Jira/GitHub/Azure DevOps/Linear integrations
- Issue importing (CSV, URLs)
- Voting history and statistics over time
- User accounts and authentication
- Premium/paid features
- Timer/countdown functionality
- Multiple facilitator accounts
- Persistent game URLs beyond session
- Light theme option
- Advanced settings

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| Backend | Elixir + Phoenix 1.8.3 |
| Real-time | Phoenix LiveView + PubSub |
| State Management | GenServer per game |
| Styling | Tailwind CSS + daisyUI |
| Icons | Heroicons |
| Session | Phoenix signed cookies |

---

## UI Screens

### 1. Landing Page (`/`)
- Dark background
- Centered content:
  - App logo/name
  - Tagline
  - "Start new game" button

### 2. Create Game (`/new` or modal)
- Game name input (placeholder: auto-generated name)
- Voting system dropdown (Fibonacci / T-Shirt)
- "Create game" button

### 3. Join Game (`/game/:id` - first visit)
- Game name displayed
- Name input field
- Role selection: Voter / Spectator
- "Join game" button

### 4. Game Room (`/game/:id` - active)
- Header: game name, user dropdown, invite button
- Main area: participant table with cards
- Optional: Current story name
- Center: Action button (Reveal cards / Start new voting)
- Bottom: Card deck (for voters)
- Statistics (after reveal)

### 5. Invite Modal
- Shareable URL displayed
- Copy button with feedback ("Copied!")

---

## User Flows

### Flow 1: Create and Start Game
1. User visits landing page
2. Clicks "Start new game"
3. Optionally enters game name, selects deck
4. Clicks "Create game"
5. Enters their display name, selects Voter
6. Arrives in empty game room
7. Shares URL with team

### Flow 2: Join Existing Game
1. User receives shared link
2. Clicks link, arrives at join screen
3. Enters display name, selects role
4. Joins game, sees other participants

### Flow 3: Complete Voting Round
1. Story name optionally set
2. All voters select their cards
3. Someone clicks "Reveal cards"
4. Everyone sees results and statistics
5. Discussion happens (outside app)
6. Someone clicks "Start new voting"
7. Repeat for next story

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| User refreshes page | Reconnects with same session, rejoins game |
| Last user leaves | Game stays alive for ~5 min grace period |
| User joins mid-voting | Can immediately vote in current round |
| User joins during reveal | Sees revealed state, can participate in next round |
| Duplicate names | Allowed (users distinguished by session) |
| Very long game name | Truncate display with ellipsis |
| No votes cast, reveal clicked | Show empty results, allow new voting |
| Story name edited | Anyone can edit story name anytime before reveal |
