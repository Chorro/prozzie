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

. base_tests_kafka.bash

##
## @brief      Wait to kafka distribution kafka_consumer_example to be ready
##
## @param      1    Kafka console consumer PID
##
## @return     Always true
##
wait_for_kafka_java_consumer_ready () {
	wait_for_message 'LEADER_NOT_AVAILABLE' "$1"
}

##
## @brief      Test prozzie kafka consume/produce command
##
test_internal_kafka () {
	declare -r kafka_cmd="${PROZZIE_PREFIX}/bin/prozzie"
	declare -r consume_cmd='kafka consume'
	declare -r produce_cmd='kafka produce'

	kafka_produce_consume "${kafka_cmd}" \
						  "${produce_cmd}" \
						  "${consume_cmd}" \
						  wait_for_kafka_java_consumer_ready
}

. test_run.sh
