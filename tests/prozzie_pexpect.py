#!/usr/bin/env python3

# This file is part of Prozzie - The Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018 Wizzie S.L.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import pexpect

import os
import sys


class Line:
    def __init__(self, s):
        self.line = s


def test_pexpect(exec_args, expected_interactions):
    """
    @brief      Test to send and receive to a prozzie command

    @param      exec_args       The linux executable args
    @param      expected_interactions  The expected interactions

    @return     Always true, exception in case of failure
    """

    logfile = sys.stdout

    bash_xtracefd = os.environ.get('BASH_XTRACEFD', False)
    spawn_kwargs = {}
    if bash_xtracefd:
        spawn_kwargs = {'pass_fds': (int(bash_xtracefd),)}

    with pexpect.spawn(exec_args,
                       logfile=logfile,
                       # Short columns make spawned output introduce '\n'
                       dimensions=[25, 2000],
                       encoding='utf-8',
                       **spawn_kwargs) as child:
        expect_patterns = list(expected_interactions.keys())
        while True:
            res_index = child.expect(expect_patterns, timeout=300)

            if expect_patterns[res_index] == pexpect.EOF:
                break

            # If the list is empty, this raises an IndexError exception. This
            # is intended.
            res = expected_interactions[expect_patterns[res_index]].pop(0)
            if res == pexpect.spawn.sendintr:
                # Send intr and exit
                child.sendintr()
                break

            expected_child_response = None

            if isinstance(res, Line) or isinstance(res, str):
                # Fire and forget string
                res_str = res
            else:
                res_str = res[0]
                expected_child_response = res[1]

            if isinstance(res_str, Line):
                child.sendline(res_str.line)
            else:
                child.send(res_str)

            if expected_child_response:
                child.expect([expected_child_response], timeout=1)

    return child.wait()
