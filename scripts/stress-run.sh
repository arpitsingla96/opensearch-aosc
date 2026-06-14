#!/bin/bash
#
# Stress-run a Gradle test task N times and aggregate results.
#
# Usage: ./scripts/stress-run.sh <gradle-task> <nruns> [--tests <filter>]
#
# Examples:
#   ./scripts/stress-run.sh itTest 10
#   ./scripts/stress-run.sh smokeTest2Nodes 5 --tests "*.SmokeMigrationCoreIT"
#   ./scripts/stress-run.sh scaleTest2Nodes 3
#
# Output: merged test results in build/stress-results/ with per-test pass/fail/flaky stats.

set -u

task=$1
nruns=$2
shift 2
extra_args="$*"

results_dir="aosc-plugin/build/stress-results"
tmp_dir="aosc-plugin/build/stress-results/runs"
rm -rf "$results_dir"
mkdir -p "$tmp_dir"

pass_count=0
fail_count=0

for i in $(seq 1 "$nruns"); do
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║  Stress run $i / $nruns: $task"
  echo "╚══════════════════════════════════════════╝"
  echo ""

  rm -rf aosc-plugin/build/test-results

  if ./gradlew --no-daemon ":aosc-plugin:$task" $extra_args 2>&1; then
    echo "✅ Run $i: PASSED"
    pass_count=$((pass_count + 1))
  else
    echo "❌ Run $i: FAILED"
    fail_count=$((fail_count + 1))
  fi

  # Collect XML results from wherever Gradle put them
  run_dir="$tmp_dir/run-$i"
  mkdir -p "$run_dir"
  find aosc-plugin/build -path "*/test-results/*/*.xml" -exec cp {} "$run_dir/" \; 2>/dev/null
done

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Stress run complete: $pass_count/$nruns passed"
echo "╚══════════════════════════════════════════╝"
echo ""

# Aggregate results
python3 scripts/stress-aggregate.py "$tmp_dir" "$nruns" "$results_dir"

# Cleanup run dirs
rm -rf "$tmp_dir"

# Exit with failure if any run failed
if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
