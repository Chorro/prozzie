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
	[NETFLOW_PROBES]="{}|JSON object of NF probes (It's recommend to use env var) "
	[NETFLOW_KAFKA_TOPIC]='flow|Topic to produce netflow traffic? ')

showVarsDescription () {
    printf '\t%-40s%s\n' 'NETFLOW_PROBES' 'JSON object of NF probes'
    printf '\t%-40s%s\n' 'NETFLOW_KAFKA_TOPIC' 'Topic to produce netflow traffic'
}
