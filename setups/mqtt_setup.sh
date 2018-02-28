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

declare -A module_envs=(
	[mqtt.server_uris]="|MQTT brokers"
	[kafka.topic]='|MQTT Topics to consume'
	[mqtt.topic]='|Topic to produce MQTT consumed messages')

declare -A module_hidden_envs=(
	[name]='mqtt'
	[connector.class]='com.evokly.kafka.connect.mqtt.MqttSourceConnector'
	[tasks.max]='1'
	[key.converter]='org.apache.kafka.connect.storage.StringConverter'
	[value.converter]='org.apache.kafka.connect.storage.StringConverter'
	[mqtt.client_id]='my-id'
	[mqtt.clean_session]='true'
	[mqtt.connection_timeout]='30'
	[mqtt.keep_alive_interval]='60'
	[mqtt.qos]='1'
	[message_processor_class]='com.evokly.kafka.connect.mqtt.sample.StringProcessor'
)

if [[ "$1" != "--source" ]]; then
	tmp_fd mqtt_properties
	kcli_setup "/dev/fd/${mqtt_properties}" "$@"
	exec {mqtt_properties}<&-
fi
