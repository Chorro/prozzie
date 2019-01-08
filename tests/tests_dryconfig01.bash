#!/usr/bin/env bash

# This file is part of Prozzie - The Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018-2019 Wizzie S.L.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

declare -r PROZZIE_PREFIX=/opt/prozzie

. base_tests_config.bash

#--------------------------------------------------------
# TEST PROZZIE CONFIG OPTIONS
#--------------------------------------------------------

testBasicHelp() {
    # prozzie config must show help with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config > config.txt
    "${PROZZIE_PREFIX}"/bin/prozzie config --help > config_help.txt

    ${_ASSERT_EQUALS_} "'prozzie$ and prozzie --help does not show the same'" \
        "'$(<config.txt)'" "'$(tail -n +2 config_help.txt)'"
}

testDescribeAll() {
    # prozzie config describe-all must describe all modules with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config describe-all
}

#--------------------------------------------------------
# TEST RESILIENCE
#--------------------------------------------------------

##
## @brief      All this arguments must fail and perform no action
##
testWrongArguments() {
    declare arg
    declare -a args=(
        'config --wrongOption'
        'config wrongAction'
        'config get wrongModule'
        'config describe'
        'config describe wrongModule'
        'config setup'
        'config setup wrongModule'
        'config get wrongModule'
        )

    for arg in "${args[@]}"; do
        printf 'Testing prozzie %s\n' "$arg"
        # shellcheck disable=SC2086
        if "${PROZZIE_PREFIX}"/bin/prozzie $arg; then
            ${_FAIL_} "'prozzie $arg must show error'"
        fi
    done
}

. test_run.sh
