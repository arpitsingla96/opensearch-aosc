# Releases

AOSC releases have two version axes:

- **AOSC version**: the plugin project version, such as `0.1.0`.
- **OpenSearch compatibility line**: the OpenSearch major/minor line the ZIP was built against, such as `os2.19`.

The plugin descriptor uses a patch-compatible semver range for the selected OpenSearch minor. For example, a ZIP built with OpenSearch `2.19.0` is intended for OpenSearch `2.19.x` unless a release note says otherwise.

## Source of Truth

The AOSC release version is tracked in `version.properties`:

```properties
aosc.version=0.1.0
```

OpenSearch compatibility metadata is tracked per release line:

```text
release/os2.properties
release/os3.properties
```

The current OpenSearch 2.x line is:

```properties
line=os2
branch=releases/2.x
primary_version=2.19.0
build_versions=2.15.0,2.17.0,2.19.0
test_versions=2.15.0,2.17.0,2.17.1,2.19.0,2.19.3
```

Release tags, asset names, GitHub Actions matrices, and release branch checks are derived from these files. Do not type release versions directly into the GitHub workflow.

## Branches

Release branches are organized by OpenSearch major line:

| Branch | Purpose |
| --- | --- |
| `main` | Active development. |
| `releases/2.x` | OpenSearch 2.x maintenance and releases. |
| `releases/3.x` | OpenSearch 3.x maintenance and releases once supported. |

GitHub release workflows must run from the branch declared in the matching `release/<line>.properties` file. For example, the OpenSearch 2.x release workflow should only publish from `releases/2.x`.

Pushing to a release branch runs CI only. Publishing is manual: run the GitHub `Release` workflow from the release branch after CI is green.

Release tags should include the OpenSearch major line, for example:

```text
aosc-0.1.0-os2
aosc-0.1.0-os3
```

Avoid ambiguous tags such as `v0.1.0` once OpenSearch 2.x and 3.x can diverge.

The release workflow fails before building if the computed release tag or GitHub release already exists. Bump `aosc.version` before publishing another release for the same OpenSearch line.

## GitHub CI Policy

Pull requests run the `pr-checks` job automatically. This job builds the docs and runs the fast, YAML REST, integration, and 2-node smoke test coverage against the current primary OpenSearch version from `release/<line>.properties`.

Before merging a PR, maintainers should also run full validation for the exact PR head commit. For same-repository branches, run the `CI` workflow manually from the GitHub Actions UI and select the PR branch. For forked PRs, apply the `full-ci` label; the pull request workflow will run the same full validation on the fork head without using repository secrets.

Full validation runs one matrix job per OpenSearch version in `test_versions`. Each matrix job runs fast checks, YAML REST tests, Java integration tests, all smoke topologies, and the high-shard scale profile in a single runner setup. Branch protection should require both stable check names:

- `pr-checks`
- `full-ci-gate`

If the PR branch changes after full validation, run full validation again before merging.

## GitHub Release Assets

Each GitHub release should include:

- one plugin ZIP per supported OpenSearch build target
- `SHA256SUMS`
- release notes with compatibility and upgrade notes
- an SBOM when available
- artifact provenance or attestation when available

Example OpenSearch 2.x assets:

```text
opensearch-aosc-0.1.0-os2.15.0.zip
opensearch-aosc-0.1.0-os2.17.0.zip
opensearch-aosc-0.1.0-os2.19.0.zip
SHA256SUMS
```

## Building Locally

Build a ZIP for one OpenSearch version:

```bash
./gradlew :aosc-plugin:bundlePlugin -Dopensearch.version=2.19.0
```

Build and rename all currently supported OpenSearch 2.x ZIPs:

```bash
./scripts/build-release-zips.sh os2
```

The script writes release assets to `build/release/`.

Inspect the release metadata with:

```bash
./scripts/release-metadata.sh os2
```

## Documentation Site

GitHub Pages is deployed by the `Pages` workflow. The workflow builds all public documentation lines into one site on every push to `main` or `releases/**`:

| Source branch | Published path |
| --- | --- |
| `main` | `/latest/` |
| `releases/2.x` | `/2.x/` |
| `releases/3.x` | `/3.x/` once the branch exists. |

The root page redirects to `/latest/` and lists the available versions. The Pages workflow rebuilds every available docs line each time so one branch does not overwrite another branch's published docs.

The workflow deploys only when the GitHub repository is public or the organization plan enables Pages for private repositories. While the repository is private without private Pages support, the Pages workflow is skipped.

Build the same versioned site locally with:

```bash
./scripts/build-pages-site.sh
```

The generated site is written to `build/pages/`.

## CI Artifacts

CI uploads Gradle reports and test results only when a validation job fails. Normal CI artifacts expire after 7 days; release workflow test artifacts expire after 14 days. Release ZIPs are not CI artifacts; they are attached to GitHub Releases.

## First Public Import

Public GitHub history starts from the OSS import. Earlier internal development history is not part of the public repository.
