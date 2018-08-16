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

# Want a literal linefeed here
#shellcheck disable=SC1004
declare -r sfacctd_aggregate='cos, etype, src_mac, dst_mac, vlan, src_host, \
	dst_host, src_mask, dst_mask, src_net, dst_net, proto, tos, src_port, \
	dst_port, tcpflags, src_as, dst_as, as_path, src_as_path, \
	src_host_country, dst_host_country, in_iface, out_iface, sampling_rate, \
	export_proto_version, timestamp_arrival'

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=(
	[SFLOW_KAFKA_TOPIC]='pmacct|Topic to produce sflow traffic'
	[SFLOW_RENORMALIZE]='true|Normalize sflow based on sampling'
	[SFLOW_AGGREGATE]="$sfacctd_aggregate"'|sfacctd aggregation fields')

showVarsDescription () {
    printf '\t%-40s%s\n' 'SFLOW_KAFKA_TOPIC' 'Topic to produce sflow traffic'
    printf '\t%-40s%s\n' 'SFLOW_RENORMALIZE' 'Normalize sflow based on sampling'
    printf '\t%-40s%s\n' 'SFLOW_AGGREGATE' 'Aggregation fields'
}

##
## @brief      Print a hint to the user about how to send messages to this
##             module. INTERFACE_IP and SFLOW_KAFKA_TOPIC environment
##             variables must be defined.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Use "%s:6343" (or reachable from probe address) as ' "$INTERFACE_IP"
	printf 'sflow collector in your probe configuration. '
	printf 'You can check that messages are produced in the topic with '
	printf '"prozzie kafka consume %s"\n' "$SFLOW_KAFKA_TOPIC"
}
