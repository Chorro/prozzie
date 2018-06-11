#!/usr/bin/env bash

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
