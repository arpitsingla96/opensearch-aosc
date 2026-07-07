# Development Environment Setup

For the public contribution contract, use the repository root [`CONTRIBUTING.md`](https://github.com/atlassian-labs/opensearch-aosc/blob/develop/CONTRIBUTING.md). It covers issues, pull requests, commit-message conventions, code formatting, and license headers.

The contributing pages in this documentation are source-tree workflow references. They cover local setup, test selection, package layout, release mechanics, and extension points for people changing AOSC code.

## Prerequisites

| Tool | Minimum | Notes |
|------|---------|-------|
| JDK | 21 for the `os3` line; 17 for the `os2` line | Set the Gradle JVM to match the line you build. `java_version` in `release/os*.properties` is the bytecode target (11 for os2, 21 for os3). |
| Git | 2.x | Source control. |
| Docker | Recent Docker Desktop or Docker Engine | Needed for Docker-backed smoke tests and local clusters. |
| Docker Compose | v2 plugin or v1 standalone | The Gradle task detects `docker compose` first, then `docker-compose`. |
| Gradle | Wrapper only | Use `./gradlew`; do not rely on a global Gradle install. |

## Build

The root build requires an OpenSearch version.

```bash
git clone https://github.com/atlassian-labs/opensearch-aosc.git
cd opensearch-aosc
./gradlew assemble -PopensearchVersion=3.6.0
```

The plugin ZIP is written under the selected line's `build/distributions/` (Gradle prints the exact path).

## Environment Variables

```bash
export OPENSEARCH_INITIAL_ADMIN_PASSWORD=Admin@123
```

Supply the OpenSearch version per command, or set a default once in `~/.gradle/gradle.properties` (`opensearchVersion=3.6.0`) so a bare `./gradlew` and IntelliJ import resolve it. The version selects the OpenSearch line (os2/os3):

```bash
./gradlew fastCheck -PopensearchVersion=3.6.0
```

## IntelliJ IDEA

1. Open the repository root.
2. Set the Gradle JVM to JDK 21 for the `os3` line or JDK 17 for the `os2` line. Only one line imports per `opensearchVersion`, so switch the Gradle JVM when you switch lines.
3. Enable annotation processing for Lombok.
4. Import the formatter profile from `gradle/formatterConfig.xml` if you want IDE formatting to match Spotless.
5. Set `opensearchVersion` in `~/.gradle/gradle.properties` (e.g. `3.6.0`) so import resolves the line; override per run configuration with `-PopensearchVersion`.

## Local Docker Cluster

From the repository root:

```bash
export OPENSEARCH_INITIAL_ADMIN_PASSWORD=Admin@123
./gradlew dockerUp -PopensearchVersion=3.6.0
curl -s http://localhost:9200/_cluster/health | jq '.'
./gradlew dockerDown -PopensearchVersion=3.6.0
```

The compose files live in the selected line's `opensearch-docker/` directory. Prefer the Gradle tasks above because they build the plugin ZIP, copy it into the Docker context, select Compose v1 or v2, wait for health, and remove volumes on shutdown.

If you debug Compose directly, first run `./gradlew dockerCopyPlugin -PopensearchVersion=3.6.0`, then run Compose from `aosc-plugin-os<N>/opensearch-docker/` with `OPENSEARCH_VERSION` (the container image tag) and `OPENSEARCH_INITIAL_ADMIN_PASSWORD` set.

## Common Setup Issues

| Problem | Fix |
|---------|-----|
| `opensearchVersion is required` | Pass `-PopensearchVersion=<version>` or set it in `~/.gradle/gradle.properties`. |
| `java: command not found` | Install a JDK and make it available on `PATH`. |
| Docker connection errors | Start Docker Desktop or Docker Engine. |
| Spotless violations | Run `./gradlew spotlessApply -PopensearchVersion=3.6.0`. |
| Lombok symbols missing in IDE | Enable annotation processing and reload Gradle. |

## Repository Layout

There is one source tree per OpenSearch line, `aosc-plugin-os2/` and `aosc-plugin-os3/`, with identical internal structure. Only the line matching `-PopensearchVersion` participates in a build.

```text
opensearch-aosc/
|-- aosc-plugin-os2/            # OpenSearch 2.x source tree (structure below)
|-- aosc-plugin-os3/            # OpenSearch 3.x source tree
|   |-- src/main/java/          # Plugin source
|   |-- src/test/               # Unit tests
|   |-- src/itTest/             # In-JVM integration tests
|   |-- src/smokeTest/          # REST smoke tests
|   |-- src/scaleTest/          # Scale validation tests
|   |-- src/benchmarkTest/      # Benchmark tests
|   |-- src/yamlRestTest/       # YAML REST tests
|   `-- opensearch-docker/      # Local Docker cluster
|-- docs/                       # VitePress documentation
|-- gradle/                     # Wrapper, formatter config, shared aosc-plugin.gradle
|-- release/                    # Per-line build manifests
`-- scripts/                    # Public helper scripts
```
