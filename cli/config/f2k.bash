#!/usr/bin/env bash

# This file is part of Prozzie - The Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018-2019 Wizzie S.L.

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

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=(
	[NETFLOW_PROBES]="{}|JSON object of NF probes (It's recommend to use env var) "
	[NETFLOW_KAFKA_TOPIC]='flow|Topic to produce netflow traffic? ')

##
## @brief      Print a hint to the user about how to send messages to this
##             module. INTERFACE_IP and NETFLOW_KAFKA_TOPIC environment
##             variables must be defined.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Use "%s:2055 (or reachable from probe address) as ' "$INTERFACE_IP"
	printf 'netflow collector in your probe configuration. '
	printf 'You can check that messages are produced in topic with '
	printf '"prozzie kafka consume %s"\n' "$NETFLOW_KAFKA_TOPIC"
}
