#!/usr/bin/env bash

if [[ ! -v PROZZIE_PREFIX ]]; then
	declare -r PROZZIE_PREFIX=/opt/prozzie/
fi

oneTimeSetUp () {
	declare -g bashopts
	bashopts=$(set +o)
	declare -r bashopts
	set -euf -o pipefail
	set -o errtrace  # Needed for inherit ERR trap
}

oneTimeTearDown () {
	$bashopts
}

# Print stack trace in case of sudden error
trap 'print_stacktrace ${LINENO};' ERR

print_stacktrace () {
	printf 'SHUNIT ERROR STACKTRACE ($$: %s, BASHPID: %s): ================\n' \
															 "$$" "$BASHPID" >&2
	declare -i i
	for (( i=1; i<${#FUNCNAME[@]}; ++i )); do
		if [[ ${FUNCNAME[$i]} == '_shunit_execSuite' ]]; then
			break
		fi

		if [[ $i -eq 1 ]]; then
			declare lineno=$1
		else
			declare line_i=$((i-1))
			declare lineno=${BASH_LINENO[$line_i]}
		fi
		printf '%s:%s\n' "${FUNCNAME[$i]}" "${lineno}" >&2
	done
	printf 'END OF SHUNIT STACKTRACE: =========\n' >&2
}

# Circleci + centos7 terminal does not do well, need to set TERM variable
if [[ ! -v TERM ]]; then
	export TERM=xterm
fi

. /usr/bin/shunit2
