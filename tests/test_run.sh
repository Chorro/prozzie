#!/usr/bin/env bash

if [[ ! -v PROZZIE_PREFIX ]]; then
	declare -r PROZZIE_PREFIX=/opt/prozzie/
fi

oneTimeSetUp () {
	declare -g bashopts
	bashopts=$(set +o)
	declare -r bashopts
	set -euf -o pipefail
}

oneTimeTearDown () {
	$bashopts
}

. /usr/bin/shunit2
