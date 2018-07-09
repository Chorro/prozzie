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
declare -A module_envs=(
	[mqtt.server_uris]='|MQTT brokers'
	[kafka.topic]="|Kafka's topic to produce MQTT consumed messages"
	[mqtt.topic]='|MQTT Topics to consume')

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
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

showVarsDescription () {
    printf '\t%-40s%s\n' 'mqtt.server_uris' 'MQTT brokers'
    printf '\t%-40s%s\n' 'kafka.topic' "Kafka's topic to produce MQTT consumed messages"
    printf '\t%-40s%s\n' 'mqtt.topic' "MQTT's topics to consume"
    printf '\t%-40s%s\n' 'name' "MQTT client's name"
    printf '\t%-40s%s\n' 'connector.class' 'MQTT connector'
    printf '\t%-40s%s\n' 'tasks.max' 'Max number of tasks'
    printf '\t%-40s%s\n' 'key.converter' 'Key converter class'
    printf '\t%-40s%s\n' 'value.converter' 'Value converter class'
    printf '\t%-40s%s\n' 'mqtt.client_id' "MQTT client's id"
    printf '\t%-40s%s\n' 'mqtt.clean_session' 'Clean session'
    printf '\t%-40s%s\n' 'mqtt.connection_timeout' 'Value converter class'
    printf '\t%-40s%s\n' 'mqtt.keep_alive_interval' 'Value converter class'
    printf '\t%-40s%s\n' 'mqtt.qosl' 'Value converter class'
    printf '\t%-40s%s\n' 'message_processor_class' 'Value converter class'
}
