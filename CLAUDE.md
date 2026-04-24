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

**Inside the console container:**
```bash
crystal src/server/start.cr              # Start API server
crystal src/server/start.cr --seed       # Seed initial admin users (prints credentials)
crystal src/server/start.cr -d -f openapi.json  # Generate OpenAPI spec
```

**Run a single spec:**
```bash
docker compose -f docker-compose.test.yml run --entrypoint "bash -c" --rm cmd \
  "crystal spec spec/domains/accounts/commands/opening/request_spec.cr"
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
    → API Controller  (app/src/domains/{domain}/api/)
    → Command         (app/src/domains/{domain}/commands/)
    → Event appended  (app/src/domains/{domain}/events/)
    → Event Bus       (app/src/config/initializers/event_bus.cr)
    → Projection      (app/src/domains/{domain}/projections/)  ← writes to DB
    → Query           (app/src/domains/{domain}/queries/)       ← reads from DB
```

**Database layout:**
- `eventstore` schema — immutable event log (event store)
- `projections` schema — denormalized read models
- `pgmq` schema — queue used exclusively for async event delivery

**Cross-domain interaction** happens in exactly two ways:
1. The event bus wires cross-domain command triggers (e.g. a completed approval triggers the originating domain's command)
2. A command calls another domain's Query to read state

**Approval workflow** is a generic subsystem in `domains/approvals/`. Any domain can require maker-checker by generating an approval-request event and listening for the approval-completion event.

**Multi-tenancy / access control:**
- Scopes form a hierarchy; every resource belongs to a scope
- Permissions (~75) are defined via DSL in `app/src/config/permissions.cr`
- A `Context` object (user ID, roles, scopes, requested permission) flows from the API middleware into every command and query
- Queries **automatically** filter by `context.available_scopes`

---

## Do's

- **Follow the pipeline.** Commands generate events; projections consume events; queries read projections. Never shortcut this.
- **Keep domains isolated.** A command may call another domain's Query. It may subscribe to another domain's events via the bus. Those are the only two coupling points.
- **Use the permission DSL** (`app/src/config/permissions.cr`) to add new permissions — don't hardcode permission strings anywhere.
- **Use optimistic locking.** Pass the aggregate's current version when appending events to prevent concurrent modifications.
- **Test with factories + `apply_projection()`.** Seed events directly into the store via factories, replay through the bus with `apply_projection(aggregate_id)`, then assert on projection state.
- **Put new account/currency/payment types in `app/src/config/types/`.** That's where the type catalogue lives.
- **Wire new event-bus subscriptions in `app/src/config/initializers/event_bus.cr`** — that file is the single source of truth for cross-domain event wiring.
- **Register every new event class in `app/src/config/initializers/event_handlers.cr`** — the event store uses this registry to deserialize events when hydrating aggregates. Every event defined with `define_event` must have a matching `event_handlers.register(...)` call, or hydration will fail at runtime.

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
