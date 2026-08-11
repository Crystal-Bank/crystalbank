# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About CrystalBank

An open-source, event-sourced multi-purpose ledger system built in Crystal. It demonstrates core banking concepts (accounts, double-entry bookkeeping, SEPA payments, multi-layer approval workflows, RBAC) on top of PostgreSQL as the only infrastructure dependency.

**Stack:** Crystal >= 1.14.0 · PostgreSQL · Svelte 5 + Vite · Docker

---

## Commands

```bash
make dev              # Build image, start all services, open console
make start            # Start services without interactive console
make stop / make down # Stop / stop-and-remove containers
make restart          # Restart dev environment
make reset            # Full reset (wipe data, rebuild image)
make lint             # Crystal formatter in check mode
make test             # Run all specs (docker-compose.test.yml)
make test-clean       # Remove test database data
make build-frontend   # Compile Svelte SPA to app/public/
make logs             # Tail docker logs
```

**Inside the console container** (the repo's `app/` directory is mounted at `/app`):
```bash
crystal src/server/start.cr              # Start API server
crystal src/server/start.cr --seed       # Seed initial admin users (prints credentials)
crystal src/server/start.cr -d -f openapi.json  # Generate OpenAPI spec
```

**Run a single spec** (note: spec paths mirror `app/src/domains/`, including nested domains):
```bash
docker compose -f docker-compose.test.yml -p crystalbank run --entrypoint "bash -c" --rm cmd \
  "crystal spec spec/domains/account_management/accounts/commands/opening/request_spec.cr"
```

**Frontend dev (hot reload):**
```bash
cd app/frontend && npm install && npm run dev
```

---

## Architecture

CrystalBank is a strict **Event Sourcing + CQRS** system. Every state change flows through this pipeline:

```
HTTP Request
    → API Controller  (api/)          validates request, checks permission
    → Command struct  (commands/)     pure data — aggregate_id + payload
    → CommandHandler  (commands/)     validates business rules, appends the event
    → Event appended  (events/)       immutable fact, written to event store
    → Event Bus       (app/src/config/initializers/event_bus.cr)
    → Reactor         (reactors/)     ← reacts to an event, calls the next CommandHandler
    → Projection      (projections/)  ← writes read model to DB
    → Query           (queries/)      ← reads from DB, scope-filtered
```

CrystalBank is built on [crystal-es](https://github.com/tristanholl/crystal-es), which draws a hard line between a **Command** (a pure data struct — `aggregate_id` plus typed payload, no behavior) and its **CommandHandler** (hydrates the aggregate, enforces invariants, appends events). A **Reactor** is the only thing that may subscribe to the event bus on the app side; it consumes one event and calls a `CommandHandler` directly — it never runs business logic itself. See `docs/crystal-es-update.md` for the full rationale and the migration that introduced this split.

**Domains** live under `app/src/domains/`. Two domains have nested subdomains — their paths have one extra level:

```
app/src/domains/
├── account_management/
│   ├── accounts/            # module CrystalBank::Domains::Accounts
│   └── virtual_accounts/    # module CrystalBank::Domains::VirtualAccounts
├── api_keys/
├── approvals/
├── customers/
├── events/                  # read-only API over the event log
├── ledger/
│   └── transactions/
├── payments/
├── platform/
├── roles/
├── scopes/
└── users/
```

⚠️ **Namespace ≠ directory path.** The module namespace is `CrystalBank::Domains::{Entity}` and does *not* include the parent folder: code in `domains/account_management/accounts/` lives in `CrystalBank::Domains::Accounts`, not `...::AccountManagement::Accounts`.

**Inside each domain** the layout is always:

```
{domain}/
├── aggregates/     # hydrated from events; current state for command validation
├── api/            # controllers + request/response structs (api/concerns/)
├── commands/       # one folder per operation; each holds a Command struct + CommandHandler
├── events/         # one file per event, e.g. events/opening/requested.cr
├── projections/    # event → read-model row transformers
├── queries/        # scope-filtered reads from projection tables
├── reactors/       # one folder per operation; Reactors that bridge an event back to a command
└── load.cr         # explicit requires for every file in the domain
```

**Command naming convention** — operations that need approval come as a triad, split across `commands/` and `reactors/`:
- `commands/{operation}/request.cr` — a `Command` struct (`aggregate_id` + typed payload) plus its `CommandHandler`; the API controller resolves `Context`, builds the struct, and calls `RequestHandler#handle` directly. Validates business rules and appends the `Requested` event.
- `reactors/{operation}/on_requested.cr` — bus-triggered `Reactor`, decides auto-accept vs. approval workflow. For approval workflows it builds an `Approvals::Creation::Commands::Request` and calls its `RequestHandler` directly.
- `commands/{operation}/accept.cr` — a small `Accept` `Command` struct (usually just `aggregate_id`) plus its `CommandHandler`, which hydrates the aggregate and appends the `Accepted` event.
- `reactors/{operation}/on_approval_completed.cr` — bus-triggered `Reactor`, subscribed to `Approvals::Collection::Events::Completed`. Hydrates the approval aggregate to check `source_aggregate_type`, then calls `AcceptHandler#handle`.

A `Reactor` is the only thing that may subscribe to the event bus from application code — it never runs business logic itself, only routes an event to the right `CommandHandler`. Commands that don't act on an aggregate (read-only lookups, auth checks) aren't `ES::Command` subclasses at all — they're plain classes outside this convention.

**Database layout:**
- `eventstore` schema — immutable event log (event store)
- `projections` schema — denormalized read models
- `pgmq` schema — queue used exclusively for async event delivery

**Cross-domain interaction** happens in exactly two ways:
1. The event bus wires cross-domain command triggers (e.g. a completed approval triggers the originating domain's command)
2. A command calls another domain's Query to read state (e.g. `Customers::Queries::Customers.new.find_all(context: c, ...)`)

**Approval workflow** is a generic subsystem in `domains/approvals/`. Any domain can require maker-checker by generating an approval-request event and listening for `Approvals::Collection::Events::Completed` in `event_bus.cr`.

**Multi-tenancy / access control:**
- Scopes form a hierarchy; every resource belongs to a scope
- Permissions (~50) are defined via the `define_permissions` DSL in `app/src/config/permissions.cr`, grouped by domain
- A `Context` object (user ID, roles, scopes, requested permission) flows from the API middleware into every command and query as `c : CrystalBank::Api::Context`
- Queries **automatically** filter by `context.available_scopes`

---

## Checklist: adding a new operation to a domain

Follow these steps in order. Missing a registration step causes runtime failures, not compile errors.

1. **Event** — create `events/{operation}/{name}.cr`. Subclass `ES::Event`, include `ES::EventDSL`, use `define_event "{Aggregate}", "{aggregate}.{operation}.{name}" do ... end` with `attribute` declarations.
2. **Register the event** in `app/src/config/initializers/event_handlers.cr` with `event_handlers.register(...)`. Every event class must be registered or aggregate hydration fails at runtime.
3. **Command** — create `commands/{operation}/request.cr`: a `struct Request < ES::Command` (`aggregate_id` + typed payload) plus a `class RequestHandler < ES::CommandHandler(Request)` that validates and does `@event_store.append(event)`. If the operation needs the approval workflow, add `commands/{operation}/accept.cr` (a minimal `Accept` struct + `AcceptHandler`) and the matching reactors from step 5.
4. **Projection** — handle the new event in the domain's projection under `projections/`.
5. **Wire the bus** in `app/src/config/initializers/event_bus.cr`: `bus.subscribe(Event, Projection)` for read models, and `bus.subscribe(Event, Reactor)` for any cross-command trigger — the `Reactor` itself lives in `reactors/{operation}/on_{event}.cr` and calls the target `CommandHandler` directly.
6. **API** — add the endpoint in `api/`, with request/response structs in `api/concerns/`, declaring the required permission.
7. **Permission** — add the key to the matching group in `app/src/config/permissions.cr` (`READ_...` / `WRITE_...` naming).
8. **Require every new file** in the domain's `load.cr`. New types go in `app/src/config/types/` and are required from `app/src/config/load.cr`. New domains are required from `app/src/load.cr` — insert at the correct position, order is intentional.
9. **Spec** — mirror the source path under `app/spec/domains/...`. Seed events with the factories in `app/spec/factories/events/`, replay with `apply_projection(aggregate_id)` (defined in `spec_helper.cr`), then assert on projection state.

---

## Do's

- **Follow the pipeline.** Commands generate events; projections consume events; queries read projections. Never shortcut this.
- **Keep domains isolated.** A command may call another domain's Query. It may subscribe to another domain's events via the bus. Those are the only two coupling points.
- **Use the permission DSL** (`app/src/config/permissions.cr`) to add new permissions — don't hardcode permission strings anywhere.
- **Use optimistic locking.** Pass the aggregate's current version when appending events to prevent concurrent modifications.
- **Test with factories + `apply_projection()`.** Seed events directly into the store via factories, replay through the bus with `apply_projection(aggregate_id)`, then assert on projection state.
- **Put new account/currency/payment types in `app/src/config/types/`.** That's where the type catalogue lives.
- **Wire new event-bus subscriptions in `app/src/config/initializers/event_bus.cr`** — that file is the single source of truth for cross-domain event wiring.
- **Register every new event class in `app/src/config/initializers/event_handlers.cr`** — the event store uses this registry to deserialize events when hydrating aggregates.
- **Copy an existing domain when unsure.** `account_management/accounts` is the most complete reference implementation (approval triad, blocking, closure, projections, specs).

---

## Don'ts — Keep the Architecture Clean

### Event Sourcing violations
- **Never mutate or delete events.** The event store is append-only. To correct state, append a new corrective event.
- **Never read the event store directly from a query or API endpoint.** All reads go through projection tables in the `projections` schema. Hydrating aggregates from the store is only for commands that need current state for validation.
- **Never put business logic in projections.** Projections transform events into query-ready rows — they must not make decisions, call commands, or trigger side effects.
- **Never put query logic in commands.** Commands validate, generate events, and return a result. They do not shape read-model responses.

### Domain isolation violations
- **Never import one domain's aggregate or projection struct directly into another domain.** Use the query interface (`{Domain}::Queries::{Entity}`) instead.
- **Never call a command from a projection.** Cross-domain command triggers belong in `event_bus.cr` subscriptions only.
- **Never share a database table between two domains.** Each domain owns its projection tables.

### Access control violations
- **Never skip scope filtering in a query.** Every query that returns user-visible data must filter on `context.available_scopes`. Omitting this leaks data across tenants.
- **Never add an API endpoint without a permission check.** Every controller action must declare and enforce the required permission via the `Context`.
- **Never bypass the approval workflow for operations that require it.** The approval system exists for regulated state transitions; a direct command that skips it breaks the audit trail.

### State management violations
- **Never soft-delete via a boolean column.** Deactivation, revocation, or removal is expressed as an event (e.g. `Revoked`, `Blocked`) that the projection applies.
- **Never store derived state that can be recomputed from events.** Projections should be rebuildable by replaying the event log.

### Loading order violations
- **Never require a domain module before its dependencies are loaded.** Loading order is intentional in `app/src/load.cr` — new domains must be inserted at the correct position.
- **Never add frontend assets to `app/public/` by hand.** That directory is the build output of `make build-frontend`; manual files will be overwritten.
