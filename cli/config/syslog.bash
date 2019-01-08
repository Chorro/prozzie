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

. "${BASH_SOURCE%/*/*}/include/config_kcli.bash"

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=()

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_hidden_envs=(
	[name]="syslog|Syslog client's name"
	[connector.class]='com.github.jcustenborder.kafka.connect.syslog.UDPSyslogSourceConnector|Connector Java class'
	[tasks.max]='1|Max number of tasks'
	[key.converter]='org.apache.kafka.connect.json.JsonConverter|Key converter Java class'
	[value.converter]='org.apache.kafka.connect.json.JsonConverter|Value converter Java class'
	[key.converter.schemas.enable]='false|Enable key schema conversion'
	[value.converter.schemas.enable]='false|Enable value schema conversion'
	[kafka.topic]="syslog|Kafka's topic"
	[syslog.host]="0.0.0.0|Syslog's host"
	[syslog.port]="1514|Syslog's port"
	[syslog.structured.data]='true|Enable structured data'
)

##
## @brief      Print a hint to the user about how to send messages to this
##             module. INTERFACE_IP and kafka_topic environment
##             variables must be defined.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Use "%s:5577/udp (or reachable from probe address) ' "$INTERFACE_IP"
	printf 'as syslog remote server in your probe configuration. '
	printf 'You can check that messages are produced in the topic with '
	# shellcheck disable=SC2154
	printf '"prozzie kafka consume %s"\n' "${kafka_topic}"
}
