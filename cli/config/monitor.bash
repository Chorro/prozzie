#!/usr/bin/env bash

# Prozzie - Wizzie Data Platform (WDP) main entrypoint
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

. "${BASH_SOURCE%/*/*}/include/config_compose.bash"

monitor_custom_mib_prompt='monitor custom mibs path (use monitor_custom_mibs'
monitor_custom_mib_prompt="$monitor_custom_mib_prompt for no custom mibs)"

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=(
	[REQUESTS_TIMEOUT]='25|Seconds between monitor polling'
	[KAFKA_TOPIC]='monitor|Topic to produce monitor metrics'
	[MONITOR_CUSTOM_MIB_PATH]="monitor_custom_mibs|$monitor_custom_mib_prompt"
	[SENSORS_ARRAY]="''|Monitor agents array")

##
## @brief      Print a hint to the user about how to send messages to this
##             connector and how to manage custom mibs.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Monitor will start to fetch messages from SNMP network elements.\n'
	printf ' If you need to send traps, you can send it to port 162, and you '
	printf 'can check they are arriving with "prozzie consume monitor" '
	printf 'command.\n'
	printf 'If you need to modify monitor mibs, you need to add them to volume '
	printf '%s.\n' "$(docker volume ls | \
		            grep --only-matching '[a-zA-Z0-9_.-]*monitor_custom_mibs$')"
	printf 'Check https://wizzie-io.github.io/prozzie/protocols/snmp for more '
	printf 'info\n'
}

##
## @brief      Check that monitor_custom_mibs is either 'monitor_custom_mibs', a
##             valid docker volume or a valid system directory
##
## @param      [--dry-run] Do not make any actual change in the volume
## @param      1 User introduced value
##
## @return     True if valid, false otherwise
##
MONITOR_CUSTOM_MIB_PATH_sanitize () {
	declare dry_run_arg
	declare -r return_value='monitor_custom_mibs'
	declare -r monitor_mibs_volume="prozzie_${return_value}"

	if [[ $1 == --dry-run ]]; then
		dry_run_arg=--dry-run
		shift
	fi

	if [[ "${return_value}" == "$1" ]] || \
			zz_docker_copy_file_to_volume \
				${dry_run_arg:-} fdv "$1" "$monitor_mibs_volume"; then
		if [[ -z $dry_run_arg ]]; then
			"${PREFIX}"/bin/prozzie compose rm -s -f monitor 2>&1 | \
				grep -v 'No such service: monitor' >&2
		fi

		printf '%s' "${return_value}"
		return 0
	fi

	{
		printf 'Invalid value %s! Please specify either ' "$1"
		printf '"%s", a valid docker volume or a valid ' "${return_value}"
		printf 'system file or directory\n'
	} >&2

	return 1
}
