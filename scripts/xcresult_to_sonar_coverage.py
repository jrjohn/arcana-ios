#!/usr/bin/env python3
"""
Convert Xcode xcresult coverage to SonarQube generic coverage XML format.
Uses per-file xccov queries for accurate line-level coverage data.
"""

import json
import subprocess
import sys
import os
import glob
import xml.etree.ElementTree as ET


def find_xcresult(path: str) -> str:
    if path.endswith(".xcresult") and os.path.exists(path):
        return path
    pattern = os.path.join(path, "Logs", "Test", "*.xcresult")
    results = glob.glob(pattern)
    if not results:
        raise FileNotFoundError(f"No .xcresult found in {pattern}")
    return sorted(results)[-1]


def get_coverage_report(xcresult_path: str) -> dict:
    """Get the high-level coverage report (targets + files list)."""
    result = subprocess.run(
        ["xcrun", "xccov", "view", "--report", "--json", xcresult_path],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"xccov report failed: {result.stderr}")
    data = json.loads(result.stdout)
    print(f"  Found {len(data.get('targets', []))} targets in coverage report")
    for t in data.get("targets", []):
        print(f"    Target: {t.get('name')} ({len(t.get('files', []))} files)")
    return data


def get_file_coverage(xcresult_path: str, file_path: str) -> list:
    """Get per-line coverage for a specific file. Returns list of {line, count} dicts."""
    result = subprocess.run(
        ["xcrun", "xccov", "view", "--file", file_path, "--json", xcresult_path],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return []
    try:
        data = json.loads(result.stdout)
        # Format: list of dicts with "line" and "count" (or executionCount)
        # Actual format depends on Xcode version; handle both
        if isinstance(data, list):
            return data
        # Some versions wrap in object
        return data.get("lines", data.get("executionCounts", []))
    except (json.JSONDecodeError, AttributeError):
        return []


def build_generic_coverage_xml(coverage: dict, xcresult_path: str, source_root: str) -> ET.Element:
    root = ET.Element("coverage", version="1")
    files_processed = 0

    for target in coverage.get("targets", []):
        target_name = target.get("name", "")
        # Skip test targets
        if "Tests" in target_name or "UITests" in target_name:
            continue

        print(f"  Processing target: {target_name}")

        for file_data in target.get("files", []):
            abs_path = file_data.get("path", "")
            if not abs_path.endswith(".swift"):
                continue

            # Quick check: skip if no executable lines
            if file_data.get("executableLines", 0) == 0:
                continue

            # Make path relative to source root
            try:
                rel_path = os.path.relpath(abs_path, source_root)
            except ValueError:
                rel_path = abs_path

            # Skip Mocks and test-support files
            if any(kw in rel_path for kw in ["Mock", "Stub", "Test", "Preview"]):
                continue

            # Skip files excluded from coverage metric (Views, DI setup, network impl, etc.)
            # These match sonar.coverage.exclusions in sonar-project.properties
            COVERAGE_EXCLUDED_FILES = {
                # SwiftUI Views & Components (not unit-testable)
                "MainView.swift", "UserListView.swift", "UserFormView.swift",
                "UserCard.swift", "AvatarView.swift", "SyncStatusBanner.swift",
                "ArcanaTheme.swift",
                # Navigation (SwiftUI-heavy)
                "NavGraph.swift",
                # App-level DI setup (requires full app environment)
                "AppDependencies.swift",
                # Network infrastructure (requires live server)
                "NetworkLogger.swift", "ApiService.swift", "NetworkMonitor.swift",
                # DAO implementations (require SwiftData / network)
                "UserRemoteDaoImpl.swift", "UserLocalDaoImpl.swift",
                "UserRemoteDaoMockImpl.swift",
                # SwiftData analytics (requires ModelContainer)
                "PersistentAnalyticsTracker.swift",
            }
            file_basename = os.path.basename(rel_path)
            if file_basename in COVERAGE_EXCLUDED_FILES:
                print(f"    [excluded] {rel_path}")
                continue

            # Try per-line data first
            line_entries = get_file_coverage(xcresult_path, abs_path)

            if line_entries:
                # Build from per-line data
                lines_map = {}
                for entry in line_entries:
                    if isinstance(entry, dict):
                        ln = entry.get("line", entry.get("lineNumber", 0))
                        count = entry.get("count", entry.get("executionCount", 0))
                    elif isinstance(entry, (int, float)):
                        # Some versions return just counts indexed by line
                        continue
                    else:
                        continue
                    if ln > 0:
                        lines_map[ln] = max(lines_map.get(ln, 0), count)
            else:
                # Fallback: use function-level data
                lines_map = {}
                for func in file_data.get("functions", []):
                    ln = func.get("lineNumber", 0)
                    count = func.get("executionCount", 0)
                    exec_lines = func.get("executableLines", 0)
                    if ln > 0 and exec_lines > 0:
                        lines_map[ln] = count
                        # Approximate: mark next few lines based on covered/executable ratio
                        covered = func.get("coveredLines", 0)
                        total = exec_lines
                        # Mark covered_count lines as covered, rest as not
                        for i in range(1, min(total, 20)):
                            if i not in lines_map:
                                lines_map[ln + i] = count if i < covered else 0

            if not lines_map:
                continue

            file_elem = ET.SubElement(root, "file", path=rel_path)
            covered = sum(1 for c in lines_map.values() if c > 0)
            total = len(lines_map)

            for ln in sorted(lines_map):
                ET.SubElement(file_elem, "lineToCover",
                              lineNumber=str(ln),
                              covered=("true" if lines_map[ln] > 0 else "false"))

            if total > 0:
                file_elem.set("comment", f"{covered}/{total} lines ({covered/total*100:.1f}%)")

            files_processed += 1
            if files_processed <= 5:
                print(f"    {rel_path}: {covered}/{total} lines")

    print(f"  Total files processed: {files_processed}")
    return root


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <xcresult_path> <output_xml>")
        sys.exit(1)

    xcresult_input = sys.argv[1]
    output_xml = sys.argv[2]
    source_root = os.getcwd()

    print(f"Source root: {source_root}")
    xcresult = find_xcresult(xcresult_input)
    print(f"xcresult: {xcresult}")

    print("Fetching coverage report...")
    coverage = get_coverage_report(xcresult)

    print("Building SonarQube generic coverage XML (per-file queries)...")
    root = build_generic_coverage_xml(coverage, xcresult, source_root)

    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    tree.write(output_xml, encoding="utf-8", xml_declaration=True)

    print(f"Written {len(root)} files to {output_xml}")


if __name__ == "__main__":
    main()
