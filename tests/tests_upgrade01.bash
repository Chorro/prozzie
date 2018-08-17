#!/usr/bin/env bash

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
