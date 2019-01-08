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

set -e

if [[ $# -gt 0 && $1 == '--shorthelp' ]]; then
	printf '%s\n' 'Handle kafka connectors'
	exit 0
fi

declare -r kafka_connect_image=gcr.io/wizzie-registry/kafka-connect-cli:1.0.3

# Don't want docker pull mess with stdout, and there is no need to do docker
# pull if no actual pull will be done.
if ! docker images "${kafka_connect_image}" | grep -q .; then
	docker pull "${kafka_connect_image}" >&2
fi

declare waiting_kafka_connect=n
while ! "${PREFIX}/bin/prozzie" compose ps kafka-connect | \
                                                     grep -q '(healthy)'; do
    if [[ "$waiting_kafka_connect" == n ]]; then
        waiting_kafka_connect=y
        printf 'Waiting kafka-connect to be ready... ' >&2
    fi
    sleep 0.5
    printf '.' >&2
done

if [[ "$waiting_kafka_connect" == y ]]; then
	printf 'OK\n' >&2
fi

docker run --network=prozzie_default --rm -i \
    -e KAFKA_CONNECT_REST='http://kafka-connect:8083' \
    "$kafka_connect_image" sh -c "kcli $*"
