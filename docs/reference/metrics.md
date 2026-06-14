# Metrics

AOSC does not currently export Prometheus metrics or OpenSearch metrics. The supported monitoring surface today is the REST status data; external tooling can poll `_list` and `_status` if it needs time-series dashboards.

Use these surfaces for monitoring today:

| Surface | What it provides |
|---------|------------------|
| `GET /_plugins/_aosc/{index}/_status` | Coordinator phase, shard phases, per-phase counters, errors. |
| `GET /_plugins/_aosc/_list` | Summary of active and terminal migrations. |
| OpenSearch logs | Structured AOSC log lines with migration, shard, phase, and event context. |
| OpenSearch node stats | Cluster health, indexing pressure, thread pools, JVM, disk, and shard state. |

Example status poll:

```bash
curl -s 'http://localhost:9200/_plugins/_aosc/my-index-v1/_status' | jq '{phase, shards}'
```

A future metrics integration may add first-class metric export, but no public metric names or PromQL queries are part of the current plugin contract.
