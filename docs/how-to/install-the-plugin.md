# Install the Plugin

Build AOSC for the OpenSearch version you run, then install the ZIP on every cluster node.

## Supported Versions

The build currently declares support for:

- OpenSearch 2.x: `2.15.0`, `2.17.0`, `2.19.0`
- OpenSearch 3.x: `3.1.0`, `3.3.0`, `3.5.0`, `3.6.0`

Patch releases within the same minor may be compatible because the plugin descriptor is rewritten to a `~X.Y.Z` semver range. Test the exact OpenSearch version before using it. See [Compatibility](../reference/compatibility.md) for the current build and test matrix.

## Build from Source

```bash
git clone https://github.com/atlassian-labs/opensearch-aosc.git
cd opensearch-aosc
./gradlew assemble -PopensearchVersion=3.6.0
```

The build prints the ZIP path when it finishes:

```text
.../build/distributions/opensearch-aosc-<version>.zip
```

Repeat the build command with a different `-PopensearchVersion=...` when you need a ZIP for another supported OpenSearch minor.

## Install from GitHub Release

Each AOSC version is a single GitHub release tagged `v<aosc-version>`. That release attaches one ZIP per supported OpenSearch minor, across both lines:

```text
opensearch-aosc-<aosc-version>-os<opensearch-minor>.zip
```

For example, the `v0.1.0` release includes a ZIP for OpenSearch `3.6.x`:

```text
opensearch-aosc-0.1.0-os3.6.zip
```

Open the `v<aosc-version>` release, download the ZIP matching your OpenSearch minor, verify it against the release's `SHA256SUMS`, then install that ZIP on each node.

## Install on Each Node

Install the plugin on every cluster-manager and data node. Installing it on all nodes is the safest default because transport actions and services are registered by the plugin.

```bash
$OPENSEARCH_HOME/bin/opensearch-plugin install file:///path/to/opensearch-aosc-<version>.zip
```

Check node roles:

```bash
curl -s 'http://localhost:9200/_cat/nodes?v&h=name,node.role'
```

Restart nodes one at a time according to your OpenSearch operating procedure.

## Verify Installation

```bash
curl -s http://localhost:9200/_cat/plugins?v | grep opensearch-aosc
curl -s http://localhost:9200/_plugins/_aosc/_list | jq '.'
```

A cluster with no migrations returns an empty `migrations` array.

## Common Problems

| Symptom | Check |
|---------|-------|
| Plugin version mismatch | Run `_cat/plugins` on all nodes and reinstall the same ZIP everywhere. |
| `opensearchVersion is required` build error | Pass `-PopensearchVersion=...` or set it in `~/.gradle/gradle.properties`. |
| Plugin does not load | Check OpenSearch logs for version mismatch, permissions, or dependency errors. |
| REST action missing | Confirm every relevant node has the plugin installed and was restarted. |
