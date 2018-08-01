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
import sys


class ControlCharacter:
    def __init__(self, char):
        self.char = char


class Line:
    def __init__(self, s):
        self.line = s


def test_help(linux_setup_path):
    # Check the FAQ link
    interface_ip_help = 'FAQ.md#kafka-reachability'

    responses_sendline = {
        'Where do you want install prozzie?': [Line('')],
        'Introduce your client API key': [Line('def')],
        'Introduce the data HTTPS endpoint URL': [Line('abc.def')],
        'Do you want that docker to start on boot?': ['y'],
        'Do you want discover the IP address automatically?': [
                                                     ('h', interface_ip_help),
                                                     ('H', interface_ip_help),
                                                     (pexpect.spawn.sendintr)],
        # We should never reach this question
        'Introduce the IP address': [],
    }

    logfile = None
    logfile = sys.stdout
    exit_status = 0

    with pexpect.spawn(linux_setup_path,
                       logfile=logfile,
                       encoding='utf-8') as child:
        expect_patterns = list(responses_sendline.keys())
        while True:
            res_index = child.expect(expect_patterns, timeout=300)

            # If the list is empty, this raises an IndexError exception. This
            # is intended.
            res = responses_sendline[expect_patterns[res_index]].pop(0)
            if res == pexpect.spawn.sendintr:
                # Send intr and exit
                child.sendintr()
                exit_status = child.wait()
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

    return exit_status


if __name__ == "__main__":
    sys.exit(test_help(sys.argv[1]))