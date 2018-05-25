#!/usr/bin/env bash

. "${PROZZIE_PREFIX}/share/prozzie/cli/include/common.bash"

declare -r kafkacat_cmd='kafkacat'
declare -r kafkacat_base_args='-b localhost:9092'
declare -r kafkacat_produce_cmd="${kafkacat_base_args} -P -t "
declare -r kafkacat_consume_cmd="${kafkacat_base_args} -d topic -C -t"

##
## @brief      Wait for a given message in file $1 appear
##
## @param      1     Grep pattern to wait
## @param      2     File to watch
##
## @return     Always true
##
wait_for_message () {
	while ! grep -i "$1" "$2" >/dev/null; do
	  	:
	done

}

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
## @brief      Wait to kafka distribution kafka_consumer_example to be ready
##
## @param      1    Kafka console consumer PID
##
## @return     Always true
##
wait_for_kafkacat_consumer_ready () {
	wait_for_message 'Fetch topic .* at offset .*' "$1"
}


##
## @brief      Template for test kafka behavior.
##
## @param      1     Kafka command
## @param      2     Kafka produce parameters
## @param      3     Kafka consume parameters
## @param      4     Kafka consumer readiness check callback. stderr will be
##                   passed as $1 to this callback
##
## @return     { description_of_the_return_value }
##
kafka_produce_consume () {
	set -e
	declare -r kafka_cmd="$1"
	declare -r produce_args="$2"
	declare -r consume_args="$3"
	declare -r wait_for_kafka_consumer_ready="$4"
	# We should be able to produce & consume from kafka
	declare kafka_topic message COPROC COPROC_PID consumer_stderr_log
	declare -r expected_message='{"my":"message"}'
	kafka_topic=$(mktemp ptXXXXXXXXXX)
	consumer_stderr_log=$(mktemp plXXXXXXXXXX)

	# Need to retry because of kafkacat sometimes miss messages
	coproc { while timeout 60 \
	               "${kafka_cmd}" $consume_args "${kafka_topic}" || true; do :
		done;
	} 2>"$consumer_stderr_log"

	"$wait_for_kafka_consumer_ready" "$consumer_stderr_log"

	printf '%s\n' "$expected_message" | \
				   "${kafka_cmd}" $produce_args "${kafka_topic}"

	IFS= read -ru "${COPROC[0]}" message

	assertEquals "${expected_message}" "${message}"

	rkill "$COPROC_PID" >/dev/null
	set +e
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

##
## @brief      Test external kafka consume/produce command
##
test_external_kafka () {
	kafka_produce_consume "${kafkacat_cmd}" \
						  "${kafkacat_produce_cmd}" \
						  "${kafkacat_consume_cmd}" \
						  wait_for_kafkacat_consumer_ready
}

##
## @brief Kafka help should give us a zero exit code, and each of subcommands
##        help
##
test_kafka_help () {
	# Only execute kafka should return OK and show help
	set -e
	"${PROZZIE_PREFIX}/bin/prozzie" kafka > /dev/null
	"${PROZZIE_PREFIX}/bin/prozzie" kafka --help > /dev/null
	set +e
}

##
## @brief Invalid kafka parameters tests
##
test_kafka_invalid_action_parameter () {
	set -e
	tmp_fd out
	tmp_fd errout

	for action in invalid consume produce topics; do
		for parameter in '' '--invalid'; do
			# Only execute kafka should return not OK and output help
			! "${PROZZIE_PREFIX}/bin/prozzie" kafka "$action" $parameter \
														> "/dev/fd/${out}" \
			                                            2> "/dev/fd/${errout}"
			# Sometimes it has a newline
			[[ "$(wc -c < /dev/fd/${out})" -lt 2 ]]
			assertNotEquals '0' "$(wc -c < /dev/fd/${errout})"
		done
	done

	set +e
}

. test_run.sh
