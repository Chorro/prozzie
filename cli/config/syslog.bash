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

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=()

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
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

showVarsDescription () {
    printf '\t%-40s%s\n' 'name' "Syslog client's name"
    printf '\t%-40s%s\n' 'connector.class' 'Connector Java class'
    printf '\t%-40s%s\n' 'tasks.max' 'Max number of tasks'
    printf '\t%-40s%s\n' 'key.converter' 'Key converter Java class'
    printf '\t%-40s%s\n' 'value.converter' 'Value converter Java class'
    printf '\t%-40s%s\n' 'key.converter.schemas.enable' 'Enable key schema conversion '
    printf '\t%-40s%s\n' 'value.converter.schemas.enable' 'Value converter Enable value schema conversion'
    printf '\t%-40s%s\n' 'kafka.topic' "Kafka's topic"
    printf '\t%-40s%s\n' 'syslog.host' "Syslog's host"
    printf '\t%-40s%s\n' 'syslog.port' "Syslog's port"
    printf '\t%-40s%s\n' 'syslog.structured.data' 'Enable structured data'
}
