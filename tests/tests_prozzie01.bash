#!/usr/bin/env bash

test_help () {
	# Prozzie must show help with no failure
	"${PROZZIE_PREFIX}/bin/prozzie" >/dev/null 2>&1
}

test_version () {
    # Prozzie must show running version with no failure
    "${PROZZIE_PREFIX}/bin/prozzie" --version >/dev/null 2>&1
}

. test_run.sh
