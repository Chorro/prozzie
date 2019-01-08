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
declare -A module_envs=(
	[mqtt.server_uris]='|MQTT brokers'
	[kafka.topic]="|Kafka's topic to produce MQTT consumed messages"
	[mqtt.topic]='|MQTT Topics to consume')

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_hidden_envs=(
	[name]="mqtt|MQTT client's name"
	[connector.class]='com.evokly.kafka.connect.mqtt.MqttSourceConnector|MQTT connector'
	[tasks.max]='1|Max number of tasks'
	[key.converter]='org.apache.kafka.connect.storage.StringConverter|Key converter class'
	[value.converter]='org.apache.kafka.connect.storage.StringConverter|Value converter class'
	[mqtt.client_id]="my-id|MQTT client's id"
	[mqtt.clean_session]='true|Clean session'
	[mqtt.connection_timeout]='30|Connection timeout to use'
	[mqtt.keep_alive_interval]='60|Keepalive interval to use'
	[mqtt.connection.retries]='60|Number of retry connection'
	[mqtt.qos]='1|Mqtt qos to use'
	[message_processor_class]='com.evokly.kafka.connect.mqtt.sample.StringProcessor|Message processor to use'
)

##
## @brief      Print a hint to the user about how to send messages to this
##             module. Needs ${kafka__topic} environment variable.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'MQTT client will fetch messages. You can check the reception with '
	# kafka_topic variable will be at this function call
	# shellcheck disable=SC2154
	printf '"prozzie kafka consume %s"\n' "${kafka__topic}"
}
