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

. "${BASH_SOURCE%/*/*}/include/config_kcli.bash"

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=(
	[aerohive.access_token]='|Access token to validate webhook callbacks'
    )

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_hidden_envs=(
	[name]='aerohive'
	[connector.class]='io.wizzie.kafka.connect.aerohive.WebhookSourceConnector'
	[tasks.max]='1'
	[key.converter]='org.apache.kafka.connect.storage.StringConverter'
	[value.converter]='org.apache.kafka.connect.storage.StringConverter'
	[aerohive.client_id]='aerohive'
	[message_processor_class]='io.wizzie.kafka.connect.aerohive.processor.StringProcessor'
)

showVarsDescription () {
    printf '\t%-40s%s\n' 'aerohive.access_token' 'Access token sent to server within an HTTP Authorization header to validate webhook callbacks'
    printf '\t%-40s%s\n' 'name' "Aerohive client's name"
    printf '\t%-40s%s\n' 'tasks.max' 'Max number of tasks'
    printf '\t%-40s%s\n' 'key.converter' 'Key converter class'
    printf '\t%-40s%s\n' 'value.converter' 'Value converter class'
    printf '\t%-40s%s\n' 'aerohive.client_id' "Aerohives client's id"
    printf '\t%-40s%s\n' 'message_processor_class' 'Value converter class'
}

##
## @brief      Print a hint to the user about how to send messages to this
##             module. Needs ${kafka__topic} environment variable.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Aerohive webhook client will receive messages. You can check the reception with '
	# kafka_topic variable will be at this function call
	# shellcheck disable=SC2154
	printf "prozzie kafka consume <topic>. Where <topic> is the defined topic in your webhook callbacks in your HiveManager account.\\n"
}
