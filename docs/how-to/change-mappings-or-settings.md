# Change Mappings or Settings

Use AOSC when the desired index change requires a new target index and the source continues to receive writes.

## 1. Decide Whether AOSC Is Needed

Some mapping additions can be made directly in OpenSearch. AOSC is useful when you need a new index, such as changing a field type, changing analyzers for existing data, removing or reshaping fields, or changing shard count.

## 2. Prepare the Target Index

Fetch the source mapping and create the target with the intended changes:

```bash
curl -s 'http://localhost:9200/my-index-v1/_mapping' | jq '.'

curl -X PUT 'http://localhost:9200/my-index-v2' \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "number_of_shards": 5,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "id": {"type": "keyword"},
        "title": {"type": "text", "analyzer": "standard"},
        "tags": {"type": "keyword"},
        "created_at": {"type": "date"}
      }
    }
  }'
```

Index sample transformed documents into a temporary index first if the mapping change is non-trivial.

## 3. Start the Migration

```bash
curl -X POST 'http://localhost:9200/_plugins/_aosc/my-index-v1/_start' \
  -H 'Content-Type: application/json' \
  -d '{
    "target_index": "my-index-v2",
    "alias": "my-index"
  }'
```

## 4. Monitor and Verify

```bash
curl -s 'http://localhost:9200/_plugins/_aosc/my-index-v1/_status' | jq '.'
curl -s 'http://localhost:9200/my-index-v2/_mapping' | jq '.'
curl -s 'http://localhost:9200/my-index-v2/_count' | jq '.count'
```

For document reshaping, see [Transform Documents](transform-documents.md).
