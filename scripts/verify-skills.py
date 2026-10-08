#!/usr/bin/env python3
"""Verify the reviewed project-local skill files without network access."""

import hashlib
import json
from pathlib import Path
import re
import subprocess


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    root = repo / ".agents" / "skills"
    entries = json.loads((root / "manifest.json").read_text())["skills"]
    expected_entry_points = set()

    for entry in entries:
        name = entry["name"]
        if not re.fullmatch(r"[a-z0-9-]+", name):
            raise ValueError(f"Invalid skill name: {name}")
        directory = root / name
        skill_file = directory / "SKILL.md"
        expected_entry_points.add(skill_file)
        content = skill_file.read_text()
        parts = content.split("---", 2)
        if len(parts) != 3 or parts[0].strip():
            raise ValueError(f"Missing frontmatter: {name}")
        header = parts[1]
        if not re.search(rf"^name:\s*{re.escape(name)}\s*$", header, re.MULTILINE):
            raise ValueError(f"Mismatched frontmatter name: {name}")
        if not re.search(r"^description:\s*\S+", header, re.MULTILINE):
            raise ValueError(f"Missing description: {name}")

        for relative_path, expected_hash in entry["sha256"].items():
            relative = Path(relative_path)
            if relative.is_absolute() or ".." in relative.parts:
                raise ValueError(f"Invalid manifest path: {relative_path}")
            file = directory / relative
            digest = hashlib.sha256(file.read_bytes()).hexdigest()
            if digest != expected_hash:
                raise ValueError(f"Unreviewed change: {file.relative_to(repo)}")
            result = subprocess.run(
                ["git", "check-ignore", "-q", "--", str(file.relative_to(repo))],
                cwd=repo,
                check=False,
            )
            if result.returncode != 1:
                raise ValueError(f"Ignored file or Git check failed: {file.relative_to(repo)}")

        for reference in re.findall(r"`(references/[^`]+)`", content):
            if not (directory / reference).is_file():
                raise ValueError(f"Missing reference in {name}: {reference}")
        if not (directory / "LICENSE").is_file():
            raise ValueError(f"Missing license: {name}")
        print(f"{name}: metadata, hashes, references, license and Git visibility OK")

    if set(root.rglob("SKILL.md")) != expected_entry_points:
        raise ValueError("Unexpected or missing skill entry points; check nested packaging")
    print(f"Verified {len(entries)} project-local skills. Reload Codex to check its skill picker.")


if __name__ == "__main__":
    main()
