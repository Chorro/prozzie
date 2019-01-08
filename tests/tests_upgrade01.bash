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

. rollbackprozzie.sh

testProzzieUpgradeHelp () {
    # prozzie upgrade --help must show help with no failure
    "${PROZZIE_PREFIX}/bin/prozzie" upgrade --help >/dev/null 2>&1
}

testProzzieCheckForUpgrade () {
    # prozzie upgrade --check must show help with no failure
    "${PROZZIE_PREFIX}/bin/prozzie" upgrade --check >/dev/null 2>&1
}

testProzzieUpgradeToGitMasterBranch () {
    "${PROZZIE_PREFIX}/bin/prozzie" upgrade --from-git -y >/dev/null 2>&1
}

testProzzieUpgradeToGitSpecificBranch () {
    "${PROZZIE_PREFIX}/bin/prozzie" upgrade --from-git=test-branch --yes >/dev/null 2>&1
}

# This test do force update to prerelease 0.5.0 and It will fail because It doesn't contain update_internal.bash script
# testProzzieUpgradeToPrerelease () {
#     "${PROZZIE_PREFIX}/bin/prozzie" upgrade --prerelease -y >/dev/null 2>&1
# }

# This test do force update to release 0.4.0 and It will fail because It doesn't contain update_internal.bash script
# testProzzieUpgradeForcedUpgrade () {
#     "${PROZZIE_PREFIX}/bin/prozzie" upgrade --force -y >/dev/null 2>&1
# }

testProzzieUpgradeToGitWrongBranch () {
    if "${PROZZIE_PREFIX}/bin/prozzie" upgrade --from-git=blablabla -y >/dev/null 2>&1; then
        ${_FAIL_} '"prozzie upgrade --from-git=blablabla must not run success"'
    fi
}

testProzzieUpgradeWrongOption () {
    if "${PROZZIE_PREFIX}/bin/prozzie" upgrade --wrongOption >/dev/null 2>&1; then
        ${_FAIL_} '"prozzie upgrade --wrongOption must not run success"'
    fi
}

. test_run.sh
