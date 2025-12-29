#!/usr/bin/env python3
from email.message import EmailMessage
import email.parser
import email.policy
import uuid
from typing import cast, ClassVar, Final
from collections.abc import Iterable
import datetime
import shlex
import mailbox
import os

from asmodeus.json import JSONableUUID
from asmodeus.taskwarrior import TaskWarrior
from asmodeus.types import NoSuchTagError, Task


MESSAGE_PARSER: Final = email.parser.BytesParser(policy=email.policy.strict)


tw = TaskWarrior()


class EmailTask(Task):
    generate_uuid: ClassVar[bool] = True
    uuid_namespace = uuid.UUID('f026abdd-74c3-4693-8cb8-f055fd7e5642')

    def __init__(self, message: EmailMessage, *args: object,
                 use_body: bool = True, parse_subject: bool = True,
                 **kwargs: object) -> None:
        super().__init__(*args, **kwargs)
        self.message = message
        if parse_subject:
            self._parse_subject()
        else:
            self.set_no_clobber('description', message['subject'])
        self.set_no_clobber('entry', message['date'].datetime)
        self.set_no_clobber('source', '\n'.join((message['to'].addresses[0].addr_spec, message['Message-ID'])))
        if use_body:
            self._parse_body()
        if not self.get('description'):
            self['description'] = "Emailed task with no description!"

    def _parse_subject(self) -> None:
        # Custom lexer that ignores quotes, since I want to be able to use
        # subjects like "Look at Alex's thing" without it falling over, while
        # quoting things when I'm adding tasks isn't very useful to me.
        lexer = shlex.shlex(self.message['subject'], posix=True)
        lexer.quotes = ''
        lexer.whitespace_split = True
        description_parts = self._filter_process_attrs(
            self._filter_process_tags(lexer))

        self.set_no_clobber('description', ' '.join(description_parts))

    def _filter_process_tags(self, parts: Iterable[str]) -> Iterable[str]:
        for part in parts:
            if part.startswith('+') and part != '+':
                self.tag(part.removeprefix('+'))
            elif part.startswith('-'):
                try:
                    self.untag(part.removeprefix('-'))
                except NoSuchTagError:
                    # Assume this just isn't a tag and treat it like a
                    # regular part of the task name.
                    yield part
            else:
                yield part

    def _filter_process_attrs(self, parts: Iterable[str]) -> Iterable[str]:
        known_columns = self.all_keys()
        for part in parts:
            try:
                attr, value = part.split(':', maxsplit=1)
            except ValueError:
                yield part
                continue

            if attr not in known_columns:
                # Not an attribute we recognise, so don't bother trying to handle it at all.
                yield part
                continue

            if self.key_is_list(attr):
                values = value.split(',')
                try:
                    current_list = self.get_typed(attr, list)
                except KeyError:
                    self[attr] = values
                else:
                    current_list.extend(values)
            else:
                self.set_no_clobber(attr, value)

    def _gen_uuid(self) -> JSONableUUID:
        return JSONableUUID.uuid5(self.uuid_namespace,
                                  self.message['Message-ID'])

    def _parse_body(self) -> None:
        body = self.message.get_body(('plain',))
        if body is not None:
            content = cast(EmailMessage, body).get_content().strip()
            if content:  # i.e. not an empty string
                self.add_annotation(content, message['date'].datetime)

    def set_no_clobber(self, key: str, value: object) -> None:
        if key in self:
            raise RuntimeError(f'Cannot clobber {key}')
        self[key] = value

    def set_if_unset(self, key: str, value: object) -> None:
        if key not in self:
            self[key] = value


class InboxEmailTask(EmailTask):
    def __init__(self, message: EmailMessage, *args: object,
                 use_body: bool = True, parse_subject: bool = True,
                 **kwargs: object) -> None:
        super().__init__(message, *args, use_body=use_body,
                         parse_subject=parse_subject,
                         **kwargs)
        self.tag('inbox')


if __name__ == '__main__':
    maildir = mailbox.Maildir(os.environ['MAILDIR_PATH'], create=False)

    # Iterate over keys rather than messages so we can get the email messages
    # as a byte string and use our message parser. This avoids being
    # constrained by the mailbox module's default parser or needing to write a
    # handler that combines both mailbox.MaildirMessage and
    # email.message.EmailMessage.
    for key in maildir.iterkeys():
        message = MESSAGE_PARSER.parsebytes(maildir.get_bytes(key))
        print(message['subject'])

        if len(message['to'].addresses) != 1:
            raise RuntimeError(f'More addresses than expected in To header {message["to"]!r}')

        match message['to'].addresses[0].username:
            case 'task':
                tw.to_taskwarrior(EmailTask(message))
            case 'inbox':
                tw.to_taskwarrior(InboxEmailTask(message))
            case _:
                raise RuntimeError(
                    f"Received email to unexpected address {message['to']!r}")

        maildir.remove(key)
