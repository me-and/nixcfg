#!/usr/bin/env python3

import json
import subprocess
import uuid
from collections import defaultdict
from datetime import UTC, datetime
from typing import Optional

from asmodeus.json import JSONableUUIDList
from asmodeus.taskwarrior import TaskWarrior
from asmodeus.types import Task, uuid_list_init


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


def common_project(projects: list[Optional[str]]) -> Optional[str]:
    if not projects:
        return "admin.inboxen.github"

    unique_projects = set(projects)
    if len(unique_projects) == 1:
        return projects[0]

    if any(project is None for project in unique_projects):
        return "admin.inboxen.github"

    split_projects = [project.split(".") for project in projects if project is not None]
    if not split_projects:
        return "admin.inboxen.github"

    common_prefix: list[str] = split_projects[0]
    for split_project in split_projects[1:]:
        prefix_length = 0
        while (
            prefix_length < len(common_prefix)
            and prefix_length < len(split_project)
            and common_prefix[prefix_length] == split_project[prefix_length]
        ):
            prefix_length += 1
        common_prefix = common_prefix[:prefix_length]
        if not common_prefix:
            return "admin.inboxen.github"

    return ".".join(common_prefix)


def add_blocking_dependency(task: Task, dependency_uuid: uuid.UUID) -> bool:
    dependencies = task.get_typed("depends", JSONableUUIDList, None)
    if dependencies is None:
        dependencies = task["depends"] = uuid_list_init()

    if dependency_uuid in dependencies:
        return False

    dependencies.append(dependency_uuid)
    return True


def make_issue_task(report_entry: dict[str, object], report_url: str) -> Task:
    kind = issue_kind_for_url(report_url)
    return Task(
        description=f"Track the GitHub {kind} at {report_url}",
        tags=["internet"],
        priority="H",
        project="admin.inboxen.github",
        ghmeta=json.dumps([report_entry], separators=(",", ":")),
    )


def make_review_task(
    *,
    report_url: str,
    description_prefix: str,
    project: Optional[str],
    ghmeta: Optional[dict[str, object]],
) -> tuple[Task, uuid.UUID]:
    blocker_uuid = uuid.uuid4()
    task_kwargs: dict[str, object] = {
        "uuid": blocker_uuid,
        "description": review_task_description(report_url=report_url, description_prefix=description_prefix),
        "tags": ["internet"],
        "priority": "H",
    }
    if project is not None:
        task_kwargs["project"] = project
    if ghmeta is not None:
        task_kwargs["ghmeta"] = json.dumps([ghmeta], separators=(",", ":"))

    return Task(**task_kwargs), blocker_uuid


def review_task_description(*, report_url: str, description_prefix: str) -> str:
    kind = issue_kind_for_url(report_url)
    return f"{description_prefix} the GitHub {kind} at {report_url}"


if __name__ == "__main__":
    tw = TaskWarrior()

    report = gh_report_issues()
    report_urls = {entry["url"] for entry in report}

    task_descriptions: set[str] = set()
    task_entries_by_url: defaultdict[str, list[tuple[Task, list[dict[str, object]]]]] = defaultdict(list)
    for task in tw.from_taskwarrior(("-COMPLETED", "-DELETED")):
        description = task.get_typed("description", str, None)
        if description is not None:
            task_descriptions.add(description)

        ghmeta = task.get_typed("ghmeta", str, None)
        if ghmeta is None:
            continue

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
            updated_at = report_entry.get("updatedAt")
            if not isinstance(updated_at, str):
                raise RuntimeError(f"Expected report entry updatedAt to be a string, got {report_entry!r}")
            report_updated_at = parse_utc_iso_timestamp(updated_at)
            all_tasks_older_or_equal = True
            for task, entries in matching_tasks:
                changed = False
                for index, entry in enumerate(entries):
                    if entry["url"] == report_url and entry != report_entry:
                        entries[index] = report_entry
                        changed = True

                if changed:
                    task["ghmeta"] = json.dumps(entries, separators=(",", ":"))
                    task_uuid = task.get_typed("uuid", uuid.UUID)
                    tasks_to_export[task_uuid] = task

                task_modified = task.get_typed("modified", datetime, None)
                if task_modified is None:
                    continue
                task_modified_utc = task_modified.astimezone(UTC)
                if task_modified_utc > report_updated_at:
                    all_tasks_older_or_equal = False

            if all_tasks_older_or_equal:
                review_description = review_task_description(
                    report_url=report_url,
                    description_prefix="Review updates to",
                )
                already_has_review = review_description in task_descriptions
                if not already_has_review:
                    blocker_project = common_project([task.get_typed("project", str, None) for task, _ in matching_tasks])
                    review_task, blocker_uuid = make_review_task(
                        report_url=report_url,
                        description_prefix="Review updates to",
                        project=blocker_project,
                        ghmeta=report_entry,
                    )
                    new_tasks.append(review_task)
                    task_descriptions.add(review_description)

                    for task, _entries in matching_tasks:
                        if add_blocking_dependency(task, blocker_uuid):
                            task_uuid = task.get_typed("uuid", uuid.UUID)
                            tasks_to_export[task_uuid] = task
        else:
            new_tasks.append(make_issue_task(report_entry, report_url))

    for url, matching_tasks in task_entries_by_url.items():
        if url in report_urls:
            continue

        review_description = review_task_description(
            report_url=url,
            description_prefix="Review the closed/missing",
        )
        if review_description in task_descriptions:
            continue

        blocker_project = common_project([task.get_typed("project", str, None) for task, _ in matching_tasks])
        review_task, blocker_uuid = make_review_task(
            report_url=url,
            description_prefix="Review the closed/missing",
            project=blocker_project,
            ghmeta=None,
        )
        new_tasks.append(review_task)
        task_descriptions.add(review_description)

        for task, _entries in matching_tasks:
            if add_blocking_dependency(task, blocker_uuid):
                task_uuid = task.get_typed("uuid", uuid.UUID)
                tasks_to_export[task_uuid] = task

    tw.to_taskwarrior([*tasks_to_export.values(), *new_tasks])
