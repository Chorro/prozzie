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

. "$(dirname "${BASH_SOURCE[0]}")/kcli_base.sh"

declare -A module_envs=()

declare -A module_hidden_envs=(
	[name]='syslog'
	[connector.class]='com.github.jcustenborder.kafka.connect.syslog.UDPSyslogSourceConnector'
	[tasks.max]='1'
	[key.converter]='org.apache.kafka.connect.json.JsonConverter'
	[value.converter]='org.apache.kafka.connect.json.JsonConverter'
	[key.converter.schemas.enable]='false'
	[value.converter.schemas.enable]='false'
	[kafka.topic]='syslog'
	[syslog.host]='0.0.0.0'
	[syslog.port]='1514'
	[syslog.structured.data]='true'
)

if [[ "$1" != "--source" ]]; then
	tmp_fd syslog_properties
	kcli_setup "/dev/fd/${syslog_properties}" "$@"
	exec {syslog_properties}<&-
fi
