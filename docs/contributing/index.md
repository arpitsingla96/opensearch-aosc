---
icon: material/source-branch
---

# Contributing

Developer setup, test commands, code layout, and release notes for contributors.

<div class="grid cards" markdown>

-   :material-laptop:{ .lg .middle } **Dev Environment**

    ---

    Tools, environment variables, IDE notes, and Docker cluster setup.

    [:octicons-arrow-right-24: Set up](dev-environment.md)

-   :material-test-tube:{ .lg .middle } **Running Tests**

    ---

    Unit, integration, YAML REST, smoke, scale, and benchmark tasks.

    [:octicons-arrow-right-24: Test](running-tests.md)

-   :material-folder-code:{ .lg .middle } **Code Organisation**

    ---

    Packages, key classes, and where changes normally go.

    [:octicons-arrow-right-24: Browse](code-organisation.md)

-   :material-tag-outline:{ .lg .middle } **Release History**

    ---

    Current public release status and compatibility notes.

    [:octicons-arrow-right-24: History](release-history.md)

</div>

## Core Local Checks

```bash
export OPENSEARCH_VERSION=2.19.0
./gradlew :aosc-plugin:fastCheck
./gradlew :aosc-plugin:yamlRestTest
./gradlew :aosc-plugin:itTest
```

The repository root `CONTRIBUTING.md` contains pull request guidance for source checkouts.
