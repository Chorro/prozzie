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
## @param      User introduced value
##
## @return     True if valid, false otherwise
##
MONITOR_CUSTOM_MIB_PATH_sanitize () {
	declare -r prozzie_toolbox_sha='1f3ef1fe86c30f604d532e133fe7964f8b7cab2fd4e140515d3e80928d93c4e6'
	declare rc=1
	declare -r return_value='monitor_custom_mibs'
	declare -r monitor_mibs_volume="prozzie_${return_value}"
	# Use of docker volume output redirection for obtain grep exit status
	if [[ "${return_value}" == "$1" ]]; then
	    rc=0
	fi

	# Sadly, there is not a more elegant way to copy stuff to a volume than
	# through a container...
	if [[ $rc -eq 1 ]] && docker volume ls -q | grep -xq "$1"; then
		docker run --rm \
			--mount "type=volume,source=$1,target=/from" \
			--mount "type=volume,source=${monitor_mibs_volume},target=/mibs" \
			--entrypoint rsync \
			"wizzieio/prozzie-toolbox@sha256:${prozzie_toolbox_sha}" \
			-a /from/ /mibs/ && rc=0
	elif [[ $rc -eq 1 && -d "$1" ]]; then
		tar c -C "$1" -f - . | \
			docker run -i --rm \
				--mount \
					  "type=volume,source=${monitor_mibs_volume},target=/mibs" \
				--workdir "/mibs" \
		        --entrypoint /bin/tar \
		        wizzieio/prozzie-toolbox \
		        x --directory /mibs -f - && rc=0
	elif [[ $rc -eq 1 && -f "$1" ]]; then
		# Shellcheck thinks that we are reading & writing in the same file
		# shellcheck disable=SC2094
		docker run --rm \
				--mount \
					"type=volume,source=${monitor_mibs_volume},target=/mibs" \
		        --entrypoint /usr/bin/tee \
		        wizzieio/prozzie-toolbox \
		        "/mibs/$(basename "$1")" < "$1" >/dev/null && rc=0
	fi

	if [[ $rc -eq 0 ]]; then
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

#shellcheck disable=2034
declare -r MONITOR_CUSTOM_MIB_PATH_is_dot_env=y
