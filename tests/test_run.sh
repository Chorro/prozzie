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

# Circleci + centos7 terminal does not do well, need to set TERM variable
if [[ ! -v TERM ]]; then
	export TERM=xterm
fi

. /usr/bin/shunit2
