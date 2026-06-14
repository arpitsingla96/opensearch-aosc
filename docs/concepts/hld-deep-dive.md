# HLD Deep Dive

This page is a design note for contributors. It describes the current public implementation at a high level and avoids release, scale, or performance claims that are not part of the source tree contract.

## Problem Statement

Many OpenSearch schema and layout changes require a new index. If the source keeps receiving writes while data is copied, the target diverges unless those writes are replayed or reconciled.

AOSC handles this for same-cluster migrations by combining:

- Backfill from source to target.
- Source-shard operation-history replay.
- Retention leases to keep replay history available.
- Per-shard workers for data movement.
- A cluster-manager coordinator for phase progression and cutover.

## Architecture

![](aosc-architecture.drawio)

| Layer | Responsibility |
|-------|----------------|
| Coordinator | Owns migration-level state and cutover. |
| Shard worker | Owns backfill, replay, convergence, and final catch-up for one source primary shard. |
| Cluster state | Active coordinator and shard phase coordination. |
| `.aosc-migrations` | Detailed migration documents and terminal records. |
| Bulk writer | Target writes with fixed or adaptive controllers. |

## State Machine

Coordinator path:

```text
INITIALIZING -> ACTIVE -> PREPARING_TARGET -> CUTTING_OVER -> CATCHING_UP -> COMPLETING -> COMPLETED
```

Shard path:

```text
PENDING -> ACQUIRING_LEASE -> BACKFILLING -> REPLAYING -> CONVERGING -> CONVERGED -> CATCHING_UP -> COMPLETING -> COMPLETED
```

Both tiers also support cancellation and failure paths. See [State Machine Reference](../reference/state-machine.md).

## Data Movement

Backfill reads source documents, applies the configured transform, and indexes target documents with the same ID and routing when routing is present.

Replay reads source operation history through OpenSearch shard APIs. Index/create operations are transformed and indexed into the target. Delete operations are applied to the target according to the detected routing mode.

## Transform Boundary

The base plugin supports the `update` script context. It compiles scripts through OpenSearch's update script context and expects scripts to mutate `ctx._source`.

The public API supports inline and stored scripts. Omit `transform_script` for identity behavior.

## Cutover Protocol

Cutover performs a source write block, final replay, document count validation, and alias swap. The write block is required so final catch-up can reach a stable point.

AOSC removes the source write block after a successful migration by default. If the alias has already been swapped, AOSC does not automatically swap it back during failure cleanup because new writes may already be landing on the target.

## Backpressure

AOSC uses:

- Per-node backfill permits to limit concurrently active shard workers.
- Fixed or adaptive batch sizing for bulk writes.
- Optional adaptive backfill concurrency.
- Overload backoff after repeated write failures.

See [Backpressure and Throttling](backpressure-and-throttling.md).

## Failure Handling

Common failure outcomes:

| Failure | Outcome |
|---------|---------|
| Worker error | Shard enters failure path; coordinator eventually fails the migration. |
| Transform runtime error | The affected worker fails to avoid silently writing bad data. |
| Target readiness timeout | Coordinator fails the migration. |
| Cutover validation failure | Coordinator fails the migration and runs cleanup. |
| User cancellation | Coordinator and workers enter cancellation cleanup. |

Target deletion is manual. Source deletion or manual alias changes during migration are operator actions outside the normal contract.

## Operational Boundary

AOSC is useful when its assumptions match your workload. It should not be presented as zero-downtime or universally safe. It has a source write block during cutover, limited built-in transform behavior, same-cluster scope, and routing constraints.
