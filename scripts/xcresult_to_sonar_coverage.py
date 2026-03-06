#!/usr/bin/env python3
"""
Convert Xcode xcresult coverage to SonarQube generic coverage XML format.
Usage: python3 scripts/xcresult_to_sonar_coverage.py <path/to/DerivedData> <output.xml>
SonarQube generic coverage: https://docs.sonarqube.org/latest/analysis/generic-test/
"""

import json
import subprocess
import sys
import os
import glob
import xml.etree.ElementTree as ET


def find_xcresult(derived_data_path: str) -> str:
    # Accept a direct .xcresult path
    if derived_data_path.endswith(".xcresult") and os.path.exists(derived_data_path):
        return derived_data_path
    pattern = os.path.join(derived_data_path, "Logs", "Test", "*.xcresult")
    results = glob.glob(pattern)
    if not results:
        raise FileNotFoundError(f"No .xcresult found in {pattern}")
    return sorted(results)[-1]  # most recent


def get_coverage_json(xcresult_path: str) -> dict:
    result = subprocess.run(
        ["xcrun", "xccov", "view", "--report", "--json", xcresult_path],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"xccov failed: {result.stderr}")
    return json.loads(result.stdout)


def build_generic_coverage_xml(coverage: dict, source_root: str) -> ET.Element:
    root = ET.Element("coverage", version="1")

    for target in coverage.get("targets", []):
        # Only process main app target (not test targets)
        target_name = target.get("name", "")
        if "Tests" in target_name or "UITests" in target_name:
            continue

        for file_data in target.get("files", []):
            path = file_data.get("path", "")
            if not path.endswith(".swift"):
                continue

            # Make path relative to source root if possible
            try:
                rel_path = os.path.relpath(path, source_root)
            except ValueError:
                rel_path = path

            # Skip Mocks and test-support files
            if "Mock" in rel_path or "Stub" in rel_path or "Test" in rel_path:
                continue

            covered_count = 0
            total_count = 0
            lines_data = {}

            for function in file_data.get("functions", []):
                for line_data in function.get("lineData", []):
                    line_no = line_data.get("line", 0)
                    exec_count = line_data.get("executionCount", 0)
                    if line_no > 0:
                        # Merge multiple function data for same line (take max)
                        if line_no not in lines_data:
                            lines_data[line_no] = exec_count
                        else:
                            lines_data[line_no] = max(lines_data[line_no], exec_count)

            if not lines_data:
                continue

            file_elem = ET.SubElement(root, "file", path=rel_path)
            for line_no in sorted(lines_data):
                exec_count = lines_data[line_no]
                ET.SubElement(file_elem, "lineToCover",
                              lineNumber=str(line_no),
                              covered=("true" if exec_count > 0 else "false"))
                total_count += 1
                if exec_count > 0:
                    covered_count += 1

            if total_count > 0:
                pct = covered_count / total_count * 100
                file_elem.set("comment",
                              f"{covered_count}/{total_count} lines ({pct:.1f}%)")

    return root


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <DerivedData_path> <output_xml>")
        sys.exit(1)

    derived_data = sys.argv[1]
    output_xml = sys.argv[2]
    source_root = os.getcwd()

    print(f"Looking for xcresult in: {derived_data}")
    xcresult = find_xcresult(derived_data)
    print(f"Found: {xcresult}")

    print("Fetching coverage data from xccov...")
    coverage = get_coverage_json(xcresult)

    print("Building SonarQube generic coverage XML...")
    root = build_generic_coverage_xml(coverage, source_root)

    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    tree.write(output_xml, encoding="utf-8", xml_declaration=True)

    file_count = len(root)
    print(f"Written {file_count} files to {output_xml}")


if __name__ == "__main__":
    main()
