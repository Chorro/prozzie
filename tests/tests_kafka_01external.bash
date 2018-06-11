#!/usr/bin/env bash

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
		'Added .* to fetch list .*')

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
