#!/usr/bin/env python3
import asmodeus.hook as h
from asmodeus.taskwarrior import TaskWarrior

if __name__ == '__main__':
    tw = TaskWarrior()
    hooks: list[h.OnAddHook] = [h.blocks,
                                h.fix_recurrence_dst,
                                h.due_end_of,
                                h.child_until,
                                h.waitingfor_adds_due,
                                h.recur_after,
                                h.fix_weekday_due,
                                h.random_delays,
                                h.inbox_if_hook_gen(h.missing_project),
                                ]

    # Work systems have a tickets report set up.
    tickets_filter = tw.get_dom('rc.report.tickets.filter').strip()

    if not tickets_filter:
        # Not work, where I want all tags to have both a project and context
        # tags.
        hooks.append(h.inbox_if_hook_gen(h.missing_context_tags))

    h.on_add(tw, hooks)
