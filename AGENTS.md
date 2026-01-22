# AGENTS.md

This repository contains a **Phoenix v1.8 + LiveView** web application.

This document is written **for autonomous coding agents**. It defines the *only supported workflows, architectural boundaries, and verification rules*. Following this strictly is required to keep the system correct, testable, and low-slop.

---

## 0. Core principles (read first)

* **HTML is the contract**: server-rendered HTML + LiveView behavior is the primary output.
* **Verification must be cheap**: prefer compiler errors, unit tests, and LiveView tests over browser automation.
* **Low surface area**: avoid unnecessary abstractions, deps, or client-side state.
* **Determinism over cleverness**: stable DOM, stable tests, stable workflows.
* **No database, no authentication**: do NOT introduce Ecto, Repo usage, or auth-related concepts.

---

## 1. Canonical agent workflow (do not invent new commands)

### Setup

```bash
mix setup
mix assets.setup
mix assets.build
```

### Run the application

```bash
mix phx.server
```

### Fast verification (during iteration)

```bash
mix test
```

or, when iterating:

```bash
mix test --stale
```

### Full verification (required before finishing)

```bash
mix precommit
```

### Debugging tests

* Single file:

  ```bash
  mix test test/path/to/file_test.exs
  ```
* Previously failed:

  ```bash
  mix test --failed
  ```

**Rule:** Never introduce new scripts or commands. All workflows must go through `mix` aliases.

---

## 2. Definition of Done (hard gate)

A change is **DONE** only if all are true:

* `mix format` produces no diff
* `mix test` passes
* `mix precommit` passes
* All new user-visible behavior has automated tests
* All LiveView pages modified include **stable DOM IDs** on key elements
* No new dependencies unless explicitly requested

If any condition fails, the change is incomplete.

---

## 3. Application architecture (anti-slop rules)

### High-level structure

* **LiveViews own UI state and events only**
* **Pure business logic lives in plain Elixir modules** (no side effects)
* **No hidden global state**

### Allowed module types

* `MyAppWeb.*Live` – LiveViews (thin)
* `MyApp.*` – pure domain / application logic
* `MyApp.*Service` – side-effectful operations (HTTP calls, system IO)

### Forbidden patterns

* No business logic inside templates
* No large anonymous functions inside LiveViews
* No `Process.sleep/1` for synchronization
* No implicit coupling between LiveViews via global state

---

## 4. LiveView state & UI rules

### Assign discipline

* Assign only what is required
* Prefer explicit assigns:

  * `:page_title`
  * `:form`
  * `:filters`
  * `:modal`
  * `:editing_id`

### DOM stability (critical for tests)

* **Every interactive element must have a stable DOM id**
* Lists must use deterministic IDs:

```heex
<div id={"item-#{item.id}"}>
```

* Buttons / actions must be addressable:

```heex
<button id={"item-#{item.id}-delete"}>
```

Never rely on text-only selectors in tests.

---

## 5. LiveView testing strategy (agent-first)

We follow a strict pyramid:

1. **Unit tests** for pure functions (fastest)
2. **LiveView tests** using `Phoenix.LiveViewTest`
3. **Browser E2E tests** – avoided unless explicitly requested

### LiveView test rules

* Always use `Phoenix.LiveViewTest`
* Always assert using:

  * `element/2`
  * `has_element?/2`
* Never assert against raw HTML strings
* Prefer asserting presence/absence of elements over text content

Example:

```elixir
assert has_element?(view, "#item-form")
```

### Debugging selector failures

When selectors fail:

```elixir
html = render(view)
document = LazyHTML.from_fragment(html)
IO.inspect(LazyHTML.filter(document, "#item-form"))
```

Adjust selectors to match *actual rendered structure*, not assumptions.

---

## 6. Forms (LiveView-driven only)

### Required pattern

* Forms **must** be driven by `to_form/2`
* Templates **must never** access raw params or changesets

LiveView:

```elixir
assign(socket, form: to_form(params))
```

Template:

```heex
<.form for={@form} id="item-form">
  <.input field={@form[:name]} />
</.form>
```

### Forbidden patterns

* `<.form let={f}>`
* Accessing params directly in templates
* Using changesets in templates

---

## 7. Time, randomness, and determinism

To keep tests deterministic:

* Do **not** call `DateTime.utc_now/0` directly in business logic
* Wrap time access:

```elixir
defmodule MyApp.Clock do
  def now, do: DateTime.utc_now()
end
```

* Tests may stub or freeze time via this module
* Do not use random values in DOM IDs or test selectors

---

## 8. External HTTP & side effects

* Use **Req** for all HTTP calls
* Wrap HTTP logic in dedicated modules
* Never call external services directly from LiveViews

Example:

```elixir
MyApp.ExternalService.fetch_data(args)
```

---

## 9. JavaScript & hooks

* Avoid JS unless necessary
* Prefer LiveView events over JS
* When JS is required:

  * Use LiveView hooks
  * Provide stable DOM IDs
  * Use `phx-update="ignore"` when JS owns the DOM

No inline `<script>` tags. No ad-hoc JS.

---

## 10. Change protocol (mandatory)

For any feature or fix:

1. Write or update pure logic modules
2. Add unit tests
3. Implement LiveView UI
4. Add LiveView tests
5. Run `mix precommit`

Skipping steps is not allowed.

---

## 11. Dependency discipline

* Prefer Elixir/Phoenix standard library
* Do not add deps unless explicitly instructed
* Any added dep must be justified in commit message

---

## 12. CI parity rule

* CI runs the same `mix precommit` alias
* No CI-only steps
* No hidden environment requirements

If it doesn’t work locally with `mix precommit`, it’s broken.

---

## Final rule

If unsure, **choose the simpler, more explicit, more testable solution**.

The goal is correctness, clarity, and agent autonomy — not cleverness.

