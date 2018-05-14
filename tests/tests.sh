#!/usr/bin/env bash

if [[ ! -v PROZZIE_PREFIX ]]; then
	declare -r PROZZIE_PREFIX=/opt/prozzie/
fi

test_help () {
	# Prozzie must show help with no failure
	"${PROZZIE_PREFIX}/bin/prozzie" >/dev/null 2>&1
	assertTrue $?
}

. /usr/bin/shunit2
