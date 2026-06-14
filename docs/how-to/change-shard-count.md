# Change Shard Count

Use AOSC when you need to move data into a target index with a different shard count and you also need operation-history replay while the source remains live.

## 1. Review Routing Risk

Shard count changes are safest when documents do not rely on custom routing. If the source uses custom routing and the routing mode falls back to the bulk API path, AOSC requires explicit consent with `accept_data_loss_if_custom_routing_is_used`.

Check the source index settings and application write path before proceeding.

## 2. Create the Target Index

Create the target with the desired shard count and copied or updated mappings:

```bash
curl -X PUT 'http://localhost:9200/my-index-v2' \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "number_of_shards": 10,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "id": {"type": "keyword"},
        "title": {"type": "text"}
      }
    }
  }'
```

## 3. Start the Migration

```bash
curl -X POST 'http://localhost:9200/_plugins/_aosc/my-index-v1/_start' \
  -H 'Content-Type: application/json' \
  -d '{
    "target_index": "my-index-v2",
    "alias": "my-index"
  }'
```

If AOSC rejects the migration because of routing risk, review the reason before setting `accept_data_loss_if_custom_routing_is_used`. Do not use that option as a generic bypass.

## 4. Monitor

```bash
curl -s 'http://localhost:9200/_plugins/_aosc/my-index-v1/_status' | jq '{phase, shards}'
```

AOSC proceeds to cutover automatically after the coordinator and shard workers reach the required phases.

## 5. Verify

After completion:

```bash
curl -s 'http://localhost:9200/_alias/my-index' | jq '.'
curl -s 'http://localhost:9200/my-index-v2/_settings' | jq '."my-index-v2".settings.index.number_of_shards'
curl -s 'http://localhost:9200/my-index-v2/_count' | jq '.count'
```

Keep the source index until your operational checks are complete.
