#!/usr/bin/env python3

import json
import subprocess
import uuid
from collections import defaultdict
from datetime import UTC, datetime

from asmodeus.taskwarrior import TaskWarrior
from asmodeus.types import Task


def gh_report_issues() -> list[dict[str, object]]:
    report_json = subprocess.check_output(["gh-report-issues"], text=True)
    report_entries = json.loads(report_json)
    if not isinstance(report_entries, list):
        raise RuntimeError(f"Expected gh-report-issues output to be a list, got {report_entries!r}")

    deduped_by_url: dict[str, dict[str, object]] = {}
    for entry in report_entries:
        if not isinstance(entry, dict):
            raise RuntimeError(f"Expected gh-report-issues entries to be objects, got {entry!r}")
        url = entry.get("url")
        if not isinstance(url, str):
            raise RuntimeError(f"Expected gh-report-issues entry to include string URL, got {entry!r}")

        url = entry["url"]
        previous = deduped_by_url.get(url)
        if previous is not None and previous != entry:
            raise RuntimeError(f"Conflicting report entries for URL {url!r}")
        deduped_by_url[url] = entry

    return list(deduped_by_url.values())


def issue_kind_for_url(url: str) -> str:
    return "PR" if "/pull/" in url else "issue"


def parse_utc_iso_timestamp(value: str) -> datetime:
    normalized = value.replace("Z", "+00:00")
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        raise RuntimeError(f"Expected timezone-aware timestamp, got {value!r}")
    return parsed.astimezone(UTC)


if __name__ == "__main__":
    tw = TaskWarrior()

    report = gh_report_issues()

    task_entries_by_url: defaultdict[str, list[tuple[Task, list[dict[str, object]]]]] = defaultdict(list)
    for task in tw.from_taskwarrior(("-COMPLETED", "-DELETED", "ghmeta.any:")):
        ghmeta = task.get_typed("ghmeta", str)
        try:
            entries = json.loads(ghmeta)
        except json.decoder.JSONDecodeError:
            raise RuntimeError(f"Failed to decode ghmeta on {task.describe()}")

        if not isinstance(entries, list):
            raise RuntimeError(f"Expected ghmeta to be a JSON list, got {entries!r}")
        for entry in entries:
            if not isinstance(entry, dict):
                raise RuntimeError(f"Expected ghmeta entries to be objects, got {entry!r}")
            url = entry.get("url")
            if not isinstance(url, str):
                raise RuntimeError(f"Expected ghmeta entry to include string URL, got {entry!r}")
            task_entries_by_url[url].append((task, entries))

    # Key by UUID so we only export each modified task once even if multiple
    # URLs in its ghmeta were updated.
    tasks_to_export: dict[uuid.UUID, Task] = {}
    new_tasks: list[Task] = []

    for report_entry in report:
        report_url = report_entry["url"]
        if not isinstance(report_url, str):
            raise RuntimeError(f"Expected report entry to include string URL, got {report_entry!r}")
        matching_tasks = task_entries_by_url.get(report_url, [])

        if matching_tasks:
            for task, entries in matching_tasks:
                changed = False
                for index, entry in enumerate(entries):
                    if entry["url"] == report_url and entry != report_entry:
                        entries[index] = report_entry
                        changed = True

                if changed:
                    task["ghmeta"] = json.dumps(entries, separators=(",", ":"))
                    updated_at = report_entry.get("updatedAt")
                    if not isinstance(updated_at, str):
                        raise RuntimeError(
                            f"Expected report entry updatedAt to be a string, got {report_entry!r}"
                        )

                    report_updated_at = parse_utc_iso_timestamp(updated_at)
                    task_modified = task.get_typed("modified", datetime, None)
                    if task_modified is None or report_updated_at > task_modified.astimezone(UTC):
                        task.tag("inbox")
                    task_uuid = task.get_typed("uuid", uuid.UUID)
                    tasks_to_export[task_uuid] = task
        else:
            kind = issue_kind_for_url(report_url)
            new_tasks.append(
                Task(
                    description=f"Track the GitHub {kind} at {report_url}",
                    tags=["inbox"],
                    ghmeta=json.dumps([report_entry], separators=(",", ":")),
                )
            )

    tw.to_taskwarrior([*tasks_to_export.values(), *new_tasks])
