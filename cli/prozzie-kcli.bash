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
#

# Kafka connect kcli prozzie subcommand wrapper
# Arguments:
#  [--shorthelp] Show a line describing subcommand
#  All other arguments will be forwarded to kcli
#
# Environment:
#  -
#
# Out:
#  kcli in/out
#
# Exit status:
#  kcli one
#

if [[ $# -gt 0 && $1 == '--shorthelp' ]]; then
	printf '%s\n' "Handle kafka connectors"
	exit 0
fi

HOST=$(prozzie config base INTERFACE_IP)

docker run --rm -i -e KAFKA_CONNECT_REST="http://${HOST}:8083" \
    gcr.io/wizzie-registry/kafka-connect-cli:1.0.3 sh -c "kcli $*"
