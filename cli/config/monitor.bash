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
	[MONITOR_REQUEST_TIMEOUT]='25|Seconds between monitor polling'
	[MONITOR_KAFKA_TOPIC]='monitor|Topic to produce monitor metrics'
	[MONITOR_CUSTOM_MIB_PATH]="monitor_custom_mibs|$monitor_custom_mib_prompt"
	[MONITOR_SENSORS_ARRAY]="''|Monitor agents array")

##
## @brief      Print a hint to the user about how to send messages to this
##             module.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Monitor will start to fetch messages from SNMP network elements.'
	printf ' If you need to send traps, you can send it to port 162, and you '
	printf 'can check they are arriving with '
	printf '"prozzie consume monitor" command.\n'
}
