#!/usr/bin/env python3

# TODO Work out how to record subprojects as belonging to the parent project.

from typing import Iterable, Mapping, Optional
from collections import defaultdict
from itertools import chain
import datetime
import sys
import uuid

from asmodeus.types import Task, uuid_list_init
from asmodeus.taskwarrior import TaskWarrior
from asmodeus.hook import CONTEXT_TAGS
from asmodeus.json import JSONable, JSONableUUIDList

def group_by_key(it: Iterable[Task],
                 key: str,
                 ) -> Mapping[str, Iterable[Task]]:
    results: defaultdict[str, list[Task]] = defaultdict(list)

    for task in it:
        value = task.get_typed(key, str, None)
        if value is not None:
            results[value].append(task)

    return results


def has_active_deps(task: Task,
                    all_tasks: Mapping[uuid.UUID, Task],
                    ) -> bool:
    deps = task.get_typed("depends", JSONableUUIDList, None)
    if deps is None:
        return False
    return any(all_tasks[dep].get_typed("status", str) == "pending" for dep in deps)


def waiting(task: Task) -> bool:
    wait = task.get_typed('wait', datetime.datetime, None)
    if wait is None:
        return False
    return wait >= datetime.datetime.now(datetime.UTC)


def check_project_tasks(project: str,
                        tasks: Iterable[Task],
                        all_tasks: Mapping[uuid.UUID, Task],
                        ) -> Iterable[Task]:
    project_tasks: list[Task] = []
    open_project_tasks: list[Task] = []
    open_tasks: list[Task] = []

    for t in tasks:
        status = t.get_typed("status", str)
        is_open = (status == "pending" or status == "recurring")
        is_project_task = t.has_tag("project")
        if is_open and is_project_task:
            project_tasks.append(t)
            open_project_tasks.append(t)
            open_tasks.append(t)
        elif is_open:
            open_tasks.append(t)
        elif is_project_task:
            project_tasks.append(t)

    if len(open_project_tasks) > 1:
        uuid_list = "\n".join(str(t["uuid"]) for t in open_project_tasks)
        for t in open_project_tasks:
            t.tag("inbox")
            t.add_annotation(
                    ("This is one of multiple project tasks with the same "
                     "project:\n")
                    + uuid_list
                    )
            yield t

    elif len(open_tasks) == 0:
        def k(t: Task) -> datetime.datetime:
            return t.get_typed("end", datetime.datetime)
        last_closed_task = max(tasks, key=k)

        if not last_closed_task.has_tag("project"):
            yield Task(
                    description=f"Project {project} had no active tasks; either complete or delete this task to close the project, or convert this task into a more useful action",
                    tags=["inbox", "project"],
                    project=project,
                    )

    elif len(open_project_tasks) == len(open_tasks):
        # There is one open task in this project, and it's a project task.
        # That's fine if:
        # -   The task also has a context tag, in which case it's both a
        #     project and an action and can be left as such.
        # -   It has dependencies in other projects.
        # -   It's "waiting".
        t = open_project_tasks[0]
        tags = t.get_tags()
        if ((set(tags) & CONTEXT_TAGS)
                or has_active_deps(t, all_tasks)
                or waiting(t)):
            pass
        else:
            t.tag("inbox")
            yield t

    elif len(open_project_tasks) == 1:
        # Check the project task has dependencies on all the open tasks.
        project_task = open_project_tasks[0]
        project_task_dependencies = project_task.get_typed("depends", JSONableUUIDList, None)
        if project_task_dependencies is None:
            project_task_dependencies = project_task["depends"] = uuid_list_init()
        task_updated = False
        for t in open_tasks:
            uuid = t["uuid"]
            if uuid != project_task["uuid"] and uuid not in project_task_dependencies:
                project_task_dependencies.append(t["uuid"])
                task_updated = True

        if task_updated:
            yield project_task


if __name__ == "__main__":
    tw = TaskWarrior()

    tasks = tw.from_taskwarrior()
    tasks_by_uuid = {t.get_typed("uuid", uuid.UUID): t for t in tasks}
    tasks_by_project = group_by_key(tasks, "project")

    tasks_to_import: list[Task] = []
    for project, task_list in tasks_by_project.items():
        tasks_to_import.extend(check_project_tasks(project, task_list, tasks_by_uuid))
    tw.to_taskwarrior(tasks_to_import)
