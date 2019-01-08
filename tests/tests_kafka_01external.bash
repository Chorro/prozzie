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

. "${PROZZIE_PREFIX}/share/prozzie/cli/include/common.bash"
. base_tests_kafka.bash

declare -r kafkacat_cmd='kafkacat'
declare -r kafkacat_base_args='-b localhost:9092'
declare -r kafkacat_produce_cmd="${kafkacat_base_args} -P -t "
declare -r kafkacat_consume_cmd="${kafkacat_base_args} -d topic -C -t"

##
## @brief      Wait to kafka distribution kafka_consumer_example to be ready
##
## @param      1    Kafka console consumer PID
##
## @return     Always true
##
wait_for_kafkacat_consumer_ready () {
	# Different versions of librdkafka throws different messages
	declare grep_msg
	grep_msg=$(str_join '\|' \
		'Fetch topic .* at offset .*' \
		'Added .* to fetch list .*' \
		'partition count is zero: should refresh metadata')

	wait_for_message "${grep_msg}" "$1"
}

##
## @brief      Test external kafka consume/produce command
##
test_external_kafka () {
	kafka_produce_consume "${kafkacat_cmd}" \
						  "${kafkacat_produce_cmd}" \
						  "${kafkacat_consume_cmd}" \
						  wait_for_kafkacat_consumer_ready
}


. test_run.sh
