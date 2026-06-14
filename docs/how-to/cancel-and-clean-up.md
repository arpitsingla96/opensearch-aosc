# Cancel and Clean Up

Cancel a migration before it completes when you want to stop backfill, replay, or cutover work.

## Cancel

```bash
curl -X POST 'http://localhost:9200/_plugins/_aosc/my-index-v1/_cancel'
```

Response shape:

```json
{
  "accepted": true,
  "phase": "CANCELLING"
}
```

Cancellation is asynchronous. Poll `_status` until the migration reaches `CANCELLED` or `FAILED`.

```bash
curl -s 'http://localhost:9200/_plugins/_aosc/my-index-v1/_status' | jq '.phase'
```

## What AOSC Cleans Up

On cancellation or failure, AOSC attempts to:

- Stop shard workers.
- Release AOSC retention leases.
- Remove the source write block if it had been applied.
- Restore transient target settings where possible.
- Leave the alias on the source if alias swap had not already completed.

AOSC does not delete the target index. Delete it manually after inspection if it is no longer needed:

```bash
curl -X DELETE 'http://localhost:9200/my-index-v2'
```

## Admin Recovery APIs

These APIs are intended for recovery after crashes or manually interrupted migrations. They default to dry-run behavior where supported.

```bash
# List AOSC-owned retention leases that would be removed
curl -X POST 'http://localhost:9200/_plugins/_aosc/_admin/_cleanup_leases'

# Remove AOSC-owned retention leases
curl -X POST 'http://localhost:9200/_plugins/_aosc/_admin/_cleanup_leases?dry_run=false'

# Preview cluster-state cleanup
curl -X POST 'http://localhost:9200/_plugins/_aosc/_admin/_clear_state'

# Clear AOSC migration state
curl -X POST 'http://localhost:9200/_plugins/_aosc/_admin/_clear_state?dry_run=false'
```

For cleanup leases, pass `index=<source-index>` to restrict the scan to one index.

Use these only after checking migration status and cluster logs.
