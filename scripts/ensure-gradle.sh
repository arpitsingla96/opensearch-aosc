#!/bin/bash
# Pre-fetch the Gradle distribution binary referenced by gradle/wrapper/gradle-wrapper.properties
# with retries and fallback mirrors.
#
# Without this, ./gradlew downloads the distribution on first run with no retry and a
# 10-second connect timeout, which fails frequently on CI when:
#   - services.gradle.org returns 5xx
#   - github.com/gradle/gradle-distributions release downloads return 502
#   - the runner has a transient network blip
#
# This script is idempotent: if the distribution is already present in the wrapper cache,
# it exits immediately.

set -euo pipefail

PROPS_FILE="gradle/wrapper/gradle-wrapper.properties"
if [ ! -f "$PROPS_FILE" ]; then
  echo "ensure-gradle: $PROPS_FILE not found; skipping"
  exit 0
fi

DIST_URL=$(grep '^distributionUrl=' "$PROPS_FILE" | sed -e 's/^distributionUrl=//' -e 's/\\:/:/g')
if [ -z "$DIST_URL" ]; then
  echo "ensure-gradle: distributionUrl missing from $PROPS_FILE; skipping"
  exit 0
fi
DIST_ZIP=$(basename "$DIST_URL")               # gradle-8.7-all.zip
DIST_NAME=$(basename "$DIST_ZIP" .zip)         # gradle-8.7-all
GRADLE_VER=$(echo "$DIST_NAME" | sed -E 's/^gradle-([0-9.]+).*/\1/')

# Wrapper cache uses MD5(distributionUrl) as the hash subdir; let gradle compute it on first run.
# We only need to drop the zip into a location gradle wrapper will accept. The simplest reliable
# approach is to download the zip to a known location and pre-populate the cache dir gradle
# expects, then let gradle wrapper hash-check it on first invocation.

# Compute the hash gradle wrapper uses (MD5 of the distribution URL)
URL_HASH=$(printf '%s' "$DIST_URL" | md5sum | awk '{print $1}')
CACHE_BASE="${GRADLE_USER_HOME:-$HOME/.gradle}/wrapper/dists/${DIST_NAME}/${URL_HASH}"
CACHE_ZIP="${CACHE_BASE}/${DIST_ZIP}"
CACHE_OK="${CACHE_BASE}/${DIST_ZIP}.ok"

if [ -f "$CACHE_OK" ] && [ -d "${CACHE_BASE}/gradle-${GRADLE_VER}" ]; then
  echo "ensure-gradle: distribution already present at $CACHE_BASE"
  exit 0
fi

mkdir -p "$CACHE_BASE"

# Fallback URL chain: primary + GitHub releases mirror.
FALLBACK_URL="https://github.com/gradle/gradle-distributions/releases/download/v${GRADLE_VER}/${DIST_ZIP}"
URLS=("$DIST_URL")
if [ "$DIST_URL" != "$FALLBACK_URL" ]; then
  URLS+=("$FALLBACK_URL")
fi

MAX_ATTEMPTS=4
DELAYS=(1 5 15 30)

download_ok=false
for url in "${URLS[@]}"; do
  echo "ensure-gradle: trying $url"
  for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    if curl --fail --location --silent --show-error \
            --connect-timeout 30 --max-time 300 \
            --retry 0 \
            -o "${CACHE_ZIP}.tmp" "$url"; then
      mv "${CACHE_ZIP}.tmp" "$CACHE_ZIP"
      download_ok=true
      break 2
    fi
    rm -f "${CACHE_ZIP}.tmp"
    if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
      delay=${DELAYS[$((attempt - 1))]}
      echo "ensure-gradle: attempt $attempt for $url failed; sleeping ${delay}s before retry"
      sleep "$delay"
    fi
  done
done

if [ "$download_ok" != "true" ]; then
  echo "ensure-gradle: ERROR — failed to download $DIST_ZIP from all sources" >&2
  exit 1
fi

# Mark the download as complete so the wrapper accepts it. The wrapper will then
# unzip into ${CACHE_BASE}/gradle-${GRADLE_VER}/ on first invocation.
touch "$CACHE_OK"
echo "ensure-gradle: downloaded $DIST_ZIP to $CACHE_ZIP"
