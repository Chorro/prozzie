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

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

declare -r sfacctd_aggregate='cos, etype, src_mac, dst_mac, vlan, src_host, \
	dst_host, src_mask, dst_mask, src_net, dst_net, proto, tos, src_port, \
	dst_port, tcpflags, src_as, dst_as, as_path, src_as_path,
	src_host_country, dst_host_country, in_iface, out_iface, sampling_rate, \
	export_proto_version, timestamp_arrival'

declare -A module_envs=(
	[SFLOW_KAFKA_TOPIC]="pmacct|Topic to produce sflow traffic"
	[SFLOW_COLLECTOR_PORT]="6343|In what port do you want to listen for sflow traffic"
	[SFLOW_RENORMALIZE]="true|Normalize sflow based on sampling"
	[SFLOW_AGGREGATE]="$sfacctd_aggregate|sfacctd aggregation fields")

if [[ "$1" != "--source" ]]; then
	app_setup
fi
