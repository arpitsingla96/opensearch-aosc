---
icon: material/lightbulb-on
---

# Concepts

Background material for understanding AOSC behavior and tradeoffs.

<div class="grid cards" markdown>

-   :material-sitemap:{ .lg .middle } **Architecture Overview**

    ---

    Coordinator, shard workers, cluster state, and `.aosc-migrations`.

    [:octicons-arrow-right-24: Read](architecture-overview.md)

-   :material-shield-check:{ .lg .middle } **Correctness Model**

    ---

    How backfill, operation-history replay, and cutover work together.

    [:octicons-arrow-right-24: Read](correctness-model.md)

-   :material-speedometer:{ .lg .middle } **Backpressure & Throttling**

    ---

    Backfill permits, fixed and adaptive controllers, and overload behavior.

    [:octicons-arrow-right-24: Read](backpressure-and-throttling.md)

-   :material-file-document-outline:{ .lg .middle } **HLD Deep Dive**

    ---

    A longer design note for contributors.

    [:octicons-arrow-right-24: Read](hld-deep-dive.md)

-   :material-scale-balance:{ .lg .middle } **Comparison & Tradeoffs**

    ---

    AOSC versus `_reindex`, shrink/split, CCR, and manual workflows.

    [:octicons-arrow-right-24: Read](comparison-and-tradeoffs.md)

</div>
