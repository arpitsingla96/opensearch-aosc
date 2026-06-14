#!/usr/bin/env python3
"""
Aggregate N stress-run test results into a single report.

For each test case across N runs, produces:
- PASS if all N runs passed
- FAIL if all N runs failed
- FLAKY if some passed and some failed

Output: merged JUnit XML files + a human-readable summary.
"""

import os
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict


def aggregate(runs_dir, num_runs, output_dir):
    # test_key -> {passes, failures, errors, skips, times, failure_messages}
    tests = defaultdict(lambda: {
        "passes": 0, "failures": 0, "errors": 0, "skips": 0,
        "times": [], "failure_messages": [], "classname": "", "suite": ""
    })

    suites_seen = set()

    # Auto-discover run directories (run-0, run-1, ... from BITBUCKET_PARALLEL_STEP)
    run_dirs = sorted([
        d for d in os.listdir(runs_dir)
        if os.path.isdir(os.path.join(runs_dir, d)) and d.startswith("run-")
    ])
    actual_runs = len(run_dirs)
    if actual_runs != num_runs:
        print(f"Warning: expected {num_runs} runs, found {actual_runs}")
        num_runs = actual_runs

    for run_name in run_dirs:
        run_dir = os.path.join(runs_dir, run_name)
        run_idx = run_name  # for error messages

        for xml_file in os.listdir(run_dir):
            if not xml_file.startswith("TEST-") or not xml_file.endswith(".xml"):
                continue

            tree = ET.parse(os.path.join(run_dir, xml_file))
            suite = tree.getroot()
            suite_name = suite.get("name", "unknown")
            suites_seen.add(suite_name)

            for tc in suite.findall("testcase"):
                name = tc.get("name")
                classname = tc.get("classname", suite_name)
                key = f"{classname}.{name}"
                t = tests[key]
                t["classname"] = classname
                t["suite"] = suite_name
                t["times"].append(float(tc.get("time", 0)))

                failure = tc.find("failure")
                error = tc.find("error")
                skipped = tc.find("skipped")

                if error is not None:
                    t["errors"] += 1
                    t["failure_messages"].append(f"{run_idx} ERROR: {error.get('message', '')}")
                elif failure is not None:
                    t["failures"] += 1
                    t["failure_messages"].append(f"{run_idx} FAIL: {failure.get('message', '')}")
                elif skipped is not None:
                    t["skips"] += 1
                else:
                    t["passes"] += 1

    # Generate summary
    os.makedirs(output_dir, exist_ok=True)

    flaky = []
    always_fail = []
    always_pass = []

    for key, t in sorted(tests.items()):
        total = t["passes"] + t["failures"] + t["errors"]
        if total == 0:
            continue
        if t["failures"] + t["errors"] == 0:
            always_pass.append(key)
        elif t["passes"] == 0:
            always_fail.append(key)
        else:
            flaky.append((key, t))

    # Print summary
    print(f"\n{'='*60}")
    print(f"STRESS TEST SUMMARY ({num_runs} runs)")
    print(f"{'='*60}")
    print(f"  Always pass:  {len(always_pass)}")
    print(f"  Always fail:  {len(always_fail)}")
    print(f"  Flaky:        {len(flaky)}")
    print(f"  Skipped:      {sum(1 for t in tests.values() if t['skips'] > 0 and t['passes'] + t['failures'] + t['errors'] == 0)}")

    if always_fail:
        print(f"\n❌ ALWAYS FAILING ({len(always_fail)}):")
        for key in always_fail:
            print(f"  - {key}")

    if flaky:
        print(f"\n⚠️  FLAKY ({len(flaky)}):")
        for key, t in flaky:
            total = t["passes"] + t["failures"] + t["errors"]
            rate = (t["failures"] + t["errors"]) / total * 100
            print(f"  - {key}  ({t['passes']}/{total} pass, {rate:.0f}% failure rate)")
            for msg in t["failure_messages"][:3]:
                print(f"      {msg}")

    print(f"{'='*60}\n")

    # Write merged JUnit XML per suite
    suites = defaultdict(list)
    for key, t in tests.items():
        suites[t["suite"]].append((key, t))

    for suite_name, suite_tests in suites.items():
        root = ET.Element("testsuite", {
            "name": suite_name,
            "tests": str(sum(t["passes"] + t["failures"] + t["errors"] + t["skips"] for _, t in suite_tests)),
            "failures": str(sum(t["failures"] for _, t in suite_tests)),
            "errors": str(sum(t["errors"] for _, t in suite_tests)),
            "skipped": str(sum(t["skips"] for _, t in suite_tests)),
        })

        for key, t in suite_tests:
            total = t["passes"] + t["failures"] + t["errors"]
            tc = ET.SubElement(root, "testcase", {
                "name": key.split(".")[-1],
                "classname": t["classname"],
                "time": str(sum(t["times"]) / max(len(t["times"]), 1)),
            })

            if t["errors"] + t["failures"] > 0:
                is_flaky = t["passes"] > 0
                status = "FLAKY" if is_flaky else ("ERROR" if t["errors"] > 0 else "FAILURE")
                msg = f"{status}: {t['passes']}/{total} passed across {num_runs} runs"
                detail = "\n".join(t["failure_messages"])
                elem_tag = "error" if t["errors"] > 0 else "failure"
                ET.SubElement(tc, elem_tag, {"message": msg}).text = detail

            if t["skips"] > 0 and total == 0:
                ET.SubElement(tc, "skipped")

        tree = ET.ElementTree(root)
        try:
            ET.indent(tree, space="    ")  # Python 3.9+
        except AttributeError:
            pass  # Skip indentation on older Python
        out_path = os.path.join(output_dir, f"TEST-{suite_name}.xml")
        tree.write(out_path, encoding="utf-8", xml_declaration=True)

    # Write summary file
    with open(os.path.join(output_dir, "STRESS-SUMMARY.txt"), "w") as f:
        f.write(f"Stress test: {num_runs} runs\n")
        f.write(f"Always pass: {len(always_pass)}\n")
        f.write(f"Always fail: {len(always_fail)}\n")
        f.write(f"Flaky: {len(flaky)}\n\n")
        if flaky:
            f.write("FLAKY TESTS:\n")
            for key, t in flaky:
                total = t["passes"] + t["failures"] + t["errors"]
                f.write(f"  {key}: {t['passes']}/{total} pass\n")
        if always_fail:
            f.write("\nALWAYS FAILING:\n")
            for key in always_fail:
                f.write(f"  {key}\n")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <runs_dir> <num_runs> <output_dir>")
        sys.exit(1)

    aggregate(sys.argv[1], int(sys.argv[2]), sys.argv[3])
