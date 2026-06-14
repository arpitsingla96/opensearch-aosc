---
icon: material/alert-circle-outline
---

# Known Limitations

This page documents current constraints visible from the public source tree. Treat it as operational guidance, not a performance guarantee.

## Source Writes Are Blocked During Cutover

AOSC applies a source write block during cutover. Writes to the source fail while the block is active.

Applications must retry rejected writes. Test your retry behavior before using AOSC on important write paths.

Atlassian has observed successful production cutovers where the application-visible write interruption was about 2 seconds to 30 seconds, including a 50 TB index at about 30 seconds. This is an observation, not an upper bound; validation, alias update, target health, cluster-manager responsiveness, shard count, document-count validation, and write load can make specific runs shorter or longer. Measure it in your environment.

## Target Index Must Already Exist

AOSC validates that the target index exists before accepting a migration. It does not create the target index for you.

Create the target with the desired mappings, settings, shard count, and replica settings before calling `_start`.

## Same Cluster Only

AOSC migrates from source to target in the same OpenSearch cluster. Cross-cluster migrations are not supported.

For cross-cluster movement, use OpenSearch features such as remote reindex, snapshot and restore, or a separate replication pipeline, depending on your requirements.

## Alias-Based Cutover Required

AOSC swaps an alias from source to target. Applications that read or write direct concrete index names will not be moved by the alias swap.

## Custom Routing and Shard Count Changes Need Review

AOSC preserves document IDs and routing values when indexing target documents. Some shard-count changes and custom-routing combinations cannot guarantee correct delete routing. In those cases, AOSC requires explicit consent through `accept_data_loss_if_custom_routing_is_used`.

Review routing behavior carefully before changing shard counts for custom-routed indices.

## Built-In Transforms Are 1:1

The built-in `update` transform modifies `ctx._source` and emits one target document per source document. It does not currently implement public skip, split, or fan-out behavior through `ctx.op`.

## Transform Runtime Errors Fail the Migration

AOSC compiles and dry-runs scripts at start, but a script can still fail on a specific document during migration. Runtime script errors fail the affected worker so the migration does not silently write incorrect data.

Write defensive scripts and test against representative data.

## No General Dry Run

AOSC has dry-run behavior for some admin cleanup APIs, but it does not provide a full migration dry-run mode. Validate risky migrations in a staging or representative cluster.

## Source and Target Cleanup Is Manual

AOSC does not delete source or target indices after completion, cancellation, or failure. Keep both until verification is complete, then delete manually according to your retention policy.

## Metrics Export Is Not Implemented

AOSC exposes progress through status APIs and logs. It does not currently export Prometheus or OpenSearch metrics.
