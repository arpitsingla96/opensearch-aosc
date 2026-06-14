#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-${ROOT_DIR}/build/pages}"
BASE_URL="${PAGES_BASE_URL:-https://atlassian-labs.github.io/opensearch-aosc/}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/aosc-pages.XXXXXX")"

VERSION_PATHS=()
VERSION_LABELS=()
VERSION_REFS=()
VERSION_BRANCHES=()
WORKTREES=()

cleanup() {
  local worktree
  for worktree in "${WORKTREES[@]:-}"; do
    git -C "${ROOT_DIR}" worktree remove --force "${worktree}" >/dev/null 2>&1 || true
  done
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

add_version() {
  VERSION_PATHS+=("$1")
  VERSION_LABELS+=("$2")
  VERSION_REFS+=("$3")
  VERSION_BRANCHES+=("$4")
}

page_url() {
  local path="$1"
  printf '%s/%s/' "${BASE_URL%/}" "${path}"
}

render_config() {
  local source_config="$1"
  local target_config="$2"
  local version_path="$3"
  local branch_name="$4"
  awk \
    -v site_url="$(page_url "${version_path}")" \
    -v edit_uri="edit/${branch_name}/docs/" \
    '
      $1 == "site_url:" { print "site_url: " site_url; next }
      $1 == "edit_uri:" { print "edit_uri: " edit_uri; next }
      { print }
    ' "${source_config}" > "${target_config}"
}

build_version() {
  local version_path="$1"
  local label="$2"
  local ref="$3"
  local branch_name="$4"
  local safe_path="${version_path//\//-}"
  local worktree="${TMP_DIR}/worktree-${safe_path}"
  local config="${worktree}/mkdocs.pages.yml"

  echo "Building ${label} docs from ${ref} into ${version_path}/"
  git -C "${ROOT_DIR}" worktree add --detach "${worktree}" "${ref}" >/dev/null
  WORKTREES+=("${worktree}")
  render_config "${worktree}/mkdocs.yml" "${config}" "${version_path}" "${branch_name}"
  (
    cd "${worktree}"
    mkdocs build --strict --config-file "${config}" --site-dir "${OUT_DIR}/${version_path}"
  )
}

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

git -C "${ROOT_DIR}" fetch --depth=1 origin main '+refs/heads/releases/*:refs/remotes/origin/releases/*'

add_version "latest" "Latest" "origin/main" "main"

while IFS= read -r ref; do
  branch_name="${ref#origin/}"
  version_path="${branch_name#releases/}"
  add_version "${version_path}" "OpenSearch ${version_path}" "${ref}" "${branch_name}"
done < <(git -C "${ROOT_DIR}" for-each-ref --format='%(refname:short)' refs/remotes/origin/releases | LC_ALL=C sort -V)

for i in "${!VERSION_PATHS[@]}"; do
  build_version "${VERSION_PATHS[$i]}" "${VERSION_LABELS[$i]}" "${VERSION_REFS[$i]}" "${VERSION_BRANCHES[$i]}"
done

cat > "${OUT_DIR}/index.html" <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="0; url=latest/">
    <title>AOSC Documentation</title>
  </head>
  <body>
    <main>
      <h1>AOSC Documentation</h1>
      <p>Redirecting to <a href="latest/">latest documentation</a>.</p>
      <h2>Versions</h2>
      <ul>
EOF

for i in "${!VERSION_PATHS[@]}"; do
  printf '        <li><a href="%s/">%s</a></li>\n' "${VERSION_PATHS[$i]}" "${VERSION_LABELS[$i]}" >> "${OUT_DIR}/index.html"
done

cat >> "${OUT_DIR}/index.html" <<'EOF'
      </ul>
    </main>
  </body>
</html>
EOF

{
  printf '[\n'
  for i in "${!VERSION_PATHS[@]}"; do
    if [[ "${i}" != "0" ]]; then
      printf ',\n'
    fi
    printf '  {"path":"%s","label":"%s","branch":"%s"}' \
      "${VERSION_PATHS[$i]}" "${VERSION_LABELS[$i]}" "${VERSION_BRANCHES[$i]}"
  done
  printf '\n]\n'
} > "${OUT_DIR}/versions.json"

touch "${OUT_DIR}/.nojekyll"
echo "Pages site written to ${OUT_DIR}"
