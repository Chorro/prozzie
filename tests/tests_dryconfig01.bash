#!/usr/bin/env bash

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
        'config set mqtt kafka.topic=myTopic'
        'config set syslog kafka.topic=myTopic'
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
