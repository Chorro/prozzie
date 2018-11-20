#!/usr/bin/env bash

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

##
## @brief      Test help when user press "H" in setup IP auto-detection.
##
test_monitor_mib_bad_path () {
    set -e
    cd ../setups

    # The volume will be used in the test
    docker volume create my_monitor_mib_volume_created || true
    docker volume ls -q | grep my_monitor_mib_volume_created

    if ! ../tests/tests_monitor01.py \
                    "${PROZZIE_PREFIX}/bin/prozzie config setup monitor"; then
        ${_FAIL_} \''Monitor bad mib protection'\'
    fi
}

test_set_monitor_bad_mib_path () {
    "${PROZZIE_PREFIX}/bin/prozzie" config enable monitor

    # Try to set a file as
    if "${PROZZIE_PREFIX}/bin/prozzie" config set monitor \
            MONITOR_CUSTOM_MIB_PATH="$(mktemp "$SHUNIT_TMPDIR/monitor_mib.XXXXXX")"; then
        ${_FAIL_} \''Can set bad monitor mib path with config set'\'
    fi
}

. test_run.sh
