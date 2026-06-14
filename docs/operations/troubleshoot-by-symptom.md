# Troubleshoot by Symptom

| Symptom | First checks | Reference |
|---------|--------------|-----------|
| `_start` fails with target not found | Confirm the target index exists. | [REST API](../reference/rest-api.md) |
| `_start` fails with plugin consistency error | Run `_cat/plugins` on all nodes. | [Install the Plugin](../how-to/install-the-plugin.md) |
| Migration stays `PENDING` | Check `aosc.backfill.max_concurrent_per_node`. | [Runbook](runbook-stuck-migration.md) |
| Migration stays `BACKFILLING` | Check target indexing pressure, bulk rejections, heap, and disk. | [Runbook](runbook-stuck-migration.md) |
| Migration stays `CONVERGING` | Check convergence gap, source write rate, and global checkpoint movement. | [Runbook](runbook-stuck-migration.md) |
| Migration fails during transform | Check shard `error` and script logs. | [Transform Documents](../how-to/transform-documents.md) |
| Writes fail during cutover | Confirm application retry behavior. | [Known Limitations](../reference/known-limitations.md) |
| Alias did not move | Check coordinator phase, alias state, and cutover errors. | [Monitor](monitor-a-migration.md) |
| Retention leases remain after failure | Confirm migration is terminal, then use cleanup lease dry-run. | [Cancel and Clean Up](../how-to/cancel-and-clean-up.md) |
| `_clear_state` is needed | Prefer cancellation first; use dry-run before clearing. | [REST API](../reference/rest-api.md) |

Useful commands:

```bash
curl -s 'http://localhost:9200/_plugins/_aosc/my-index-v1/_status' | jq '.'
curl -s 'http://localhost:9200/_plugins/_aosc/_list' | jq '.'
curl -s 'http://localhost:9200/_cluster/health' | jq '.'
curl -s 'http://localhost:9200/_cat/shards?v'
curl -s 'http://localhost:9200/_cat/plugins?v'
```
