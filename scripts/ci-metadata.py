#!/usr/bin/env python3
"""Single source of CI/release metadata for the AOSC two-line build.

Reads version.properties (aoscVersion) and release/os<major>.properties. Modes:
  --github-output       : key=value for $GITHUB_OUTPUT (per-line meta + validation matrix)
  --validation-matrix   : validation matrix JSON (test_versions x tier suites)
  --build-matrix        : release build matrix JSON (build_versions x bundlePlugin)
  --next-version <bump> : next X.Y.Z from git tags (patch|minor|major); line-independent
  --summary             : human-readable
  --shell               : KEY=VALUE for bash `source` (single line; inspection)

The selected OpenSearch version chooses the module (settings.gradle includes only the
matching one), so gradle_task values are UNQUALIFIED (e.g. 'fastCheck', 'bundlePlugin')
and are run with -PopensearchVersion=<version>.

Usage: [TIER=fast|full] [AOSC_VERSION_OVERRIDE=X.Y.Z] \\
       scripts/ci-metadata.py <os2|os3|all> <mode>
       scripts/ci-metadata.py --next-version <patch|minor|major>
"""
import json
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
LINES = ("os2", "os3")

# Validation suites per tier: (id, label, gradle task, extra gradle args).
FAST_TASKS = [
    ("fast-check", "fastCheck", "fastCheck", ""),
    ("yaml-rest", "yamlRestTest", "yamlRestTest", ""),
]
FULL_TASKS = FAST_TASKS + [
    ("integration", "itTest", "itTest", ""),
    ("smoke-2n", "smokeTest2Nodes", "smokeTest2Nodes", ""),
    ("smoke-dedicated-cm", "smokeTestDedicatedCM", "smokeTestDedicatedCM", ""),
    ("smoke-docker", "smokeTestDocker", "smokeTestDocker", ""),
    ("scale-high-shard-2n", "scaleTest high-shard 2n", "scaleTest",
     "-Dcluster.topology=2n -Dscale.profile=high-shard"),
]
# Release build: one bundlePlugin per minor.
BUILD_TASKS = [("bundle", "bundlePlugin", "bundlePlugin", "")]


def load_props(path):
    props = {}
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            props[key.strip()] = value.strip()
    return props


def csv(value):
    return [v.strip() for v in value.split(",") if v.strip()]


def line_meta(line):
    version_props = load_props(ROOT / "version.properties")
    line_file = ROOT / "release" / f"{line}.properties"
    if not line_file.exists():
        sys.exit(f"Unknown release line: {line} (expected {line_file})")
    p = load_props(line_file)
    if p.get("line") != line:
        sys.exit(f"Line mismatch: requested {line}, {line_file} declares {p.get('line')}")
    # Releases are cut from develop (version.properties is 0.0.0-dev there); the publish
    # workflow passes the real X.Y.Z via AOSC_VERSION_OVERRIDE.
    aosc = os.environ.get("AOSC_VERSION_OVERRIDE") or version_props["aoscVersion"]
    return {
        "aosc_version": aosc,
        "os_line": line,
        "primary_version": p["primary_version"],
        "build_versions": p["build_versions"],
        "test_versions": p["test_versions"],
        "java_version": p["java_version"],
        "release_tag": f"v{aosc}",
        "docs_version": aosc,
    }


def rows_for_line(line, versions_key, tasks):
    meta = line_meta(line)
    return [
        {
            "opensearch_version": version,
            "java_version": meta["java_version"],
            "os_line": line,          # cosmetic (log grouping); the version selects the module
            "id": id_,
            "label": label,
            "gradle_task": task,      # unqualified; run with -PopensearchVersion=<version>
            "gradle_args": args,
        }
        for version in csv(meta[versions_key])
        for (id_, label, task, args) in tasks
    ]


def build_matrix_for(line, versions_key, tasks):
    lines = LINES if line == "all" else (line,)
    rows = []
    for ln in lines:
        rows += rows_for_line(ln, versions_key, tasks)
    return rows


def next_version(bump):
    tags = subprocess.run(
        ["git", "tag", "--list", "v*", "--sort=-v:refname"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout.split()
    latest = next((t[1:] for t in tags if re.fullmatch(r"v\d+\.\d+\.\d+", t)), "0.0.0")
    major, minor, patch = (int(x) for x in latest.split("."))
    if bump == "major":
        return f"{major + 1}.0.0"
    if bump == "minor":
        return f"{major}.{minor + 1}.0"
    if bump == "patch":
        return f"{major}.{minor}.{patch + 1}"
    sys.exit(f"Unknown bump '{bump}' (use patch|minor|major)")


def main():
    args = sys.argv[1:]

    if args and args[0] == "--next-version":
        print(next_version(args[1] if len(args) > 1 else "patch"))
        return

    line = args[0] if args else "os3"
    mode = args[1] if len(args) > 1 else "--summary"
    tier_tasks = FULL_TASKS if os.environ.get("TIER", "full") == "full" else FAST_TASKS

    if mode == "--build-matrix":
        print(json.dumps(build_matrix_for(line, "build_versions", BUILD_TASKS)))

    elif mode == "--validation-matrix":
        print(json.dumps(build_matrix_for(line, "test_versions", tier_tasks)))

    elif mode == "--github-output":
        lines = []
        if line != "all":
            meta = line_meta(line)
            lines += [f"{k}={v}" for k, v in meta.items()]
            lines.append("build_versions_json=" + json.dumps(csv(meta["build_versions"])))
            lines.append("test_versions_json=" + json.dumps(csv(meta["test_versions"])))
        lines.append("validation_matrix_json="
                     + json.dumps(build_matrix_for(line, "test_versions", tier_tasks)))
        text = "\n".join(lines) + "\n"
        gh_output = os.environ.get("GITHUB_OUTPUT")
        if gh_output:
            with open(gh_output, "a") as fh:
                fh.write(text)
        else:
            sys.stdout.write(text)

    elif mode == "--shell":
        if line == "all":
            sys.exit("--shell requires a single line (os2|os3)")
        for key, value in line_meta(line).items():
            print(f"{key.upper()}={value}")

    elif mode == "--summary":
        if line == "all":
            print(f"Lines: os2 + os3 (tier={os.environ.get('TIER', 'full')})")
        else:
            for key, value in line_meta(line).items():
                print(f"{key}: {value}")
        print(f"Validation rows: {len(build_matrix_for(line, 'test_versions', tier_tasks))}")
        print(f"Build rows: {len(build_matrix_for(line, 'build_versions', BUILD_TASKS))}")

    else:
        sys.exit("Usage: [TIER=fast|full] ci-metadata.py <os2|os3|all> "
                 "[--github-output|--validation-matrix|--build-matrix|--summary|--shell]  "
                 "|  ci-metadata.py --next-version <patch|minor|major>")


if __name__ == "__main__":
    main()
