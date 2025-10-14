#!/usr/bin/env python3

import asmodeus.hook as h
from asmodeus.taskwarrior import TaskWarrior

if __name__ == '__main__':
    tw = TaskWarrior()
    hooks: list[h.OnModifyHook] = [h.blocks,
                                   h.due_end_of,
                                   h.child_until,
                                   h.waitingfor_adds_due,
                                   h.recur_after,
                                   h.random_delays,
                                   h.problem_tag_hook_gen(h.missing_project_problem),
                                   ]

    # Work systems have a tickets report set up.
    tickets_filter = tw.get_dom('rc.report.tickets.filter').strip()

    if not tickets_filter:
        # Not work, where I want all tags to have both a project and context
        # tags.
        hooks.append(h.problem_tag_hook_gen(h.missing_context_problem))

    h.on_modify(tw, hooks)
