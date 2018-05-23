#!/usr/bin/env bash

test_help () {
	# Prozzie must show help with no failure
	"${PROZZIE_PREFIX}/bin/prozzie" >/dev/null 2>&1
	assertTrue $?
}

. test_run.sh
