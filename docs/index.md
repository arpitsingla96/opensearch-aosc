---
hide:
  - toc
---

# AOSC - Automatic Online Schema Change

AOSC moves an OpenSearch index to a pre-created target index while the source remains live for most of the migration. It backfills existing documents, replays source operation history, then briefly blocks source writes to finish catch-up and swap an alias.

<div class="grid cards" markdown>

-   :material-rocket-launch:{ .lg .middle } **Get Started**

    ---

    Learn the model and run a local migration.

    [:octicons-arrow-right-24: Start here](get-started/index.md)

-   :material-book-open-variant:{ .lg .middle } **How-to Guides**

    ---

    Install the plugin, prepare a target index, transform documents, and clean up.

    [:octicons-arrow-right-24: Browse guides](how-to/index.md)

-   :material-monitor-dashboard:{ .lg .middle } **Operations**

    ---

    Monitor migrations and diagnose common stuck phases.

    [:octicons-arrow-right-24: Ops notes](operations/index.md)

-   :material-code-braces:{ .lg .middle } **Reference**

    ---

    REST API, settings, state machine phases, errors, and current limitations.

    [:octicons-arrow-right-24: Look it up](reference/index.md)

-   :material-lightbulb-on:{ .lg .middle } **Concepts**

    ---

    Architecture, correctness model, backpressure, and tradeoffs.

    [:octicons-arrow-right-24: Deep dives](concepts/index.md)

-   :material-source-branch:{ .lg .middle } **Contributing**

    ---

    Local development, tests, and contribution conventions.

    [:octicons-arrow-right-24: Contribute](contributing/index.md)

</div>

## Why AOSC?

Many OpenSearch index properties cannot be changed in place. Changing field types, analyzers, routing assumptions, or shard counts usually means creating a new index and copying data.

AOSC automates the parts that are risky to do by hand:

- Backfill source documents into the target.
- Replay source-shard operation history so writes during backfill are applied to the target.
- Track per-shard progress and expose status through REST APIs.
- Perform alias cutover after a source write block and final catch-up.

AOSC still requires planning. The target index must be created first, applications must use an alias for cutover, and applications must retry writes rejected during the cutover write block.

## API Shape

These examples assume the source index, pre-created target index, and write alias already exist. For a runnable local walkthrough, start with [Your First Migration](get-started/your-first-migration.md).

```bash
# Start a migration from source index my-index-v1 to target my-index-v2
curl -X POST 'http://localhost:9200/_plugins/_aosc/my-index-v1/_start' \
  -H 'Content-Type: application/json' \
  -d '{"target_index":"my-index-v2","alias":"my-index"}'

# Check migration status
curl -s 'http://localhost:9200/_plugins/_aosc/my-index-v1/_status' | jq '.'

# Cancel a migration
curl -X POST 'http://localhost:9200/_plugins/_aosc/my-index-v1/_cancel'

# List migrations
curl -s 'http://localhost:9200/_plugins/_aosc/_list' | jq '.'
```

See [REST API Reference](reference/rest-api.md) for request and response details.
