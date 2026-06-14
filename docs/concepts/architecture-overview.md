# Architecture Overview

AOSC separates migration orchestration from shard-local data movement.

## Architecture Diagram

![](aosc-architecture.drawio)

## Components

| Component | Role |
|-----------|------|
| Coordinator | Runs on the cluster-manager node. Owns coordinator phase transitions and cutover. |
| Shard worker | Runs on a data node that holds a source primary shard. Performs backfill and replay for that shard. |
| Backfill permit manager | Limits how many shard workers per node may do heavy backfill work at once. |
| Bulk writer | Sends transformed index/delete operations to the target. |
| `.aosc-migrations` | Stores migration documents and detailed progress snapshots. |
| Cluster state | Carries active coordinator and shard phase state. |

## Data Flow

```mermaid
graph LR
    Source[Source index] -->|Backfill docs| Worker[Shard worker]
    Source -->|Operation history| Worker
    Worker -->|Bulk index/delete| Target[Target index]
    Worker -->|Shard progress| State[Cluster state]
    Coord[Coordinator] -->|Phase changes| State
    Coord -->|Alias swap| Alias[Index alias]
```

## Start Preconditions

Before accepting a migration, AOSC validates that:

- Source and target indices exist.
- Source and target index names are different.
- The alias is valid for cutover.
- The plugin is installed consistently on all nodes.
- The target routing mode can be handled, or explicit consent has been provided for risky routing cases.
- The transform and validation query are valid enough to start.

AOSC does not create the target index.

## Migration Lifecycle

1. `INITIALIZING`: create the migration record and prepare workers.
2. `ACTIVE`: workers backfill and replay until converged.
3. `PREPARING_TARGET`: restore target settings and wait for readiness.
4. `CUTTING_OVER`: apply source write block and flush source.
5. `CATCHING_UP`: workers replay final operations.
6. `COMPLETING`: validate, swap alias, remove source write block if configured, and clean up.
7. Terminal phase: `COMPLETED`, `CANCELLED`, or `FAILED`.

## Failure Model

AOSC prefers failing closed over serving a partial cutover. Before alias swap, failure should leave the alias on the source. If alias swap has already completed, AOSC does not roll the alias back automatically because writes may already be landing on the target.

Cancellation and failure cleanup release leases and remove the source write block where possible. Target index deletion is manual.

## Data Model

| Class | Purpose |
|-------|---------|
| `MigrationRequest` | User-submitted start request. |
| `MigrationRequestOptions` | Per-migration overrides. |
| `MigrationDocument` | Detailed migration document persisted in `.aosc-migrations`. |
| `MigrationSummary` | Slim list API projection. |
| `ShardProgressDocument` | Per-shard phase and per-phase counters. |
| `CoordinatorPhase` | Migration-level state enum. |
| `ShardPhase` | Worker-level state enum. |
