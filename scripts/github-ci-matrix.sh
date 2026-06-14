#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINE="${1:-os2}"
FORMAT="${2:---summary}"

# shellcheck disable=SC1090
source <("${ROOT_DIR}/scripts/release-metadata.sh" "${LINE}" --shell)

csv_to_json() {
  local csv="$1"
  local IFS=','
  local first=true

  printf '['
  for value in ${csv}; do
    if [[ "${first}" == "true" ]]; then
      first=false
    else
      printf ','
    fi
    printf '"%s"' "${value}"
  done
  printf ']'
}

smoke_task() {
  case "$1" in
    docker) printf '%s\n' "smokeTestDocker" ;;
    *) printf '%s\n' "smokeTest" ;;
  esac
}

smoke_matrix_json() {
  local versions_csv="$1"
  local topologies_csv="$2"
  local IFS=','
  local first=true
  local version
  local topology

  printf '['
  for version in ${versions_csv}; do
    for topology in ${topologies_csv}; do
      if [[ "${first}" == "true" ]]; then
        first=false
      else
        printf ','
      fi
      printf '{"opensearch_version":"%s","topology":"%s","task":"%s"}' \
        "${version}" "${topology}" "$(smoke_task "${topology}")"
    done
  done
  printf ']'
}

scale_matrix_json() {
  local versions_csv="$1"
  local IFS=','
  local first=true
  local version

  printf '['
  for version in ${versions_csv}; do
    if [[ "${first}" == "true" ]]; then
      first=false
    else
      printf ','
    fi
    printf '{"opensearch_version":"%s","topology":"2n","profile":"high-shard"}' "${version}"
  done
  printf ']'
}

emit_github_output() {
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    emit_output_lines >> "${GITHUB_OUTPUT}"
  else
    emit_output_lines
  fi
}

emit_output_lines() {
  {
    echo "aosc_version=${AOSC_VERSION}"
    echo "os_line=${OS_LINE}"
    echo "release_branch=${RELEASE_BRANCH}"
    echo "primary_version=${PRIMARY_VERSION}"
    echo "build_versions=${BUILD_VERSIONS}"
    echo "test_versions=${TEST_VERSIONS}"
    echo "release_tag=${RELEASE_TAG}"
    echo "build_versions_json=$(csv_to_json "${BUILD_VERSIONS}")"
    echo "test_versions_json=$(csv_to_json "${TEST_VERSIONS}")"
    echo "pr_smoke_matrix_json=$(smoke_matrix_json "${BUILD_VERSIONS}" "cm,docker")"
    echo "main_smoke_matrix_json=$(smoke_matrix_json "${TEST_VERSIONS}" "2n,cm,docker")"
    echo "scale_matrix_json=$(scale_matrix_json "${TEST_VERSIONS}")"
  }
}

case "${FORMAT}" in
  --github-output)
    emit_github_output
    ;;
  --summary)
    "${ROOT_DIR}/scripts/release-metadata.sh" "${LINE}" --summary
    echo "Build versions JSON: $(csv_to_json "${BUILD_VERSIONS}")"
    echo "Test versions JSON: $(csv_to_json "${TEST_VERSIONS}")"
    ;;
  *)
    echo "Usage: scripts/github-ci-matrix.sh [os-line] [--summary|--github-output]" >&2
    exit 1
    ;;
esac
