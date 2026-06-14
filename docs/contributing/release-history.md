# Release History

No public AOSC release has been documented in this branch yet.

## Current Source Compatibility

The build currently declares these OpenSearch versions in `aosc-plugin/build.gradle`:

| OpenSearch version | Role in build |
|--------------------|---------------|
| `2.15.0` | Supported build target. |
| `2.17.0` | Supported build target. |
| `2.19.0` | Primary development target. |

The plugin descriptor is rewritten to use a patch-compatible semver range for the selected minor version. Treat compatibility with untested patch releases as something to verify before use.

## Build a Release Candidate

Build the plugin for the OpenSearch minor you intend to test or publish:

```bash
./gradlew :aosc-plugin:assemble -Dopensearch.version=2.19.0
```

Repeat the command with another declared OpenSearch version when preparing artifacts for more than one minor.

## Release Policy

This branch does not currently document a public release cadence, LTS policy, or roadmap. Until maintainers publish that policy, assume releases are best-effort Atlassian Labs releases.

## Before Publishing a Release

Maintainers should verify at least:

- Source tree is public-safe.
- README and docs match the tagged source.
- `:aosc-plugin:fastCheck` passes for the primary target.
- `:aosc-plugin:yamlRestTest` passes for the primary target.
- `:aosc-plugin:itTest` passes for the primary target.
- Plugin ZIP installs on each supported OpenSearch version.
- Release notes accurately describe changes and known limitations.
- Artifacts are traceable to the public source tag.

## Runtime Version Checks

Installed plugin versions can be checked with:

```bash
curl -s 'http://localhost:9200/_cat/plugins?v'
```

A built ZIP descriptor can be inspected with:

```bash
unzip -p aosc-plugin/build/distributions/opensearch-aosc-*.zip plugin-descriptor.properties
```
