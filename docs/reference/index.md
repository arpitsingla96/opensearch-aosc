---
icon: material/code-braces
---

# Reference

Reference material for the current public source tree.

<div class="grid cards" markdown>

-   :material-api:{ .lg .middle } **REST API**

    ---

    Endpoint paths, query parameters, request fields, and response shapes.

    [:octicons-arrow-right-24: Endpoints](rest-api.md)

-   :material-cog:{ .lg .middle } **Configuration**

    ---

    Cluster settings and per-migration options.

    [:octicons-arrow-right-24: Settings](configuration.md)

-   :material-state-machine:{ .lg .middle } **State Machine**

    ---

    Coordinator and shard phases.

    [:octicons-arrow-right-24: Phases](state-machine.md)

-   :material-alert-octagon:{ .lg .middle } **Error Reference**

    ---

    Common validation and runtime errors.

    [:octicons-arrow-right-24: Errors](error-codes.md)

-   :material-chart-bar:{ .lg .middle } **Metrics**

    ---

    Current monitoring surface and what is not exported yet.

    [:octicons-arrow-right-24: Metrics](metrics.md)

-   :material-alert-circle-outline:{ .lg .middle } **Known Limitations**

    ---

    Write blocks, routing constraints, target index requirements, and unsupported workflows.

    [:octicons-arrow-right-24: Limitations](known-limitations.md)

</div>

## Quick Facts

- REST namespace: `/_plugins/_aosc`
- Settings prefix: `aosc.*`
- Target index: must be pre-created
- Terminal coordinator phases: `COMPLETED`, `CANCELLED`, `FAILED`
- Terminal shard phases: `COMPLETED`, `CANCELLED`, `FAILED`
- Built-in transform context: `update`
- Metrics: status APIs and logs only; no Prometheus or OpenSearch metrics are exported by the plugin today
