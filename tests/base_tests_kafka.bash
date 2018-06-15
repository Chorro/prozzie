#!/usr/bin/env bash

new_random_topic () {
	mktemp ptXXXXXXXXXX
}

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
## @brief  Checks that there is no broker option in kafka output message (passed
##         as stdin
##
## @return Always true or assert failure
##
assert_no_kafka_server_parameter () {
    declare out
    if out=$(grep -- '--zookeeper\|--broker-list\|--bootstrap-server\|--new_consumer'); then
        fail "line [$out] in help message"
    fi
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
	declare -r kafka_cmd="$1"
	declare -r produce_args="$2"
	declare -r consume_args="$3"
	declare -r wait_for_kafka_consumer_ready="$4"
	# We should be able to produce & consume from kafka
	declare kafka_topic message COPROC COPROC_PID consumer_stderr_log
	declare -r expected_message='{"my":"message"}'
	kafka_topic=$(new_random_topic)
	consumer_stderr_log=$(mktemp plXXXXXXXXXX)

	# Want to expand arguments, so...
	# shellcheck disable=SC2086
	# Need to retry because of kafkacat sometimes miss messages
	coproc { while timeout 60 \
	               "${kafka_cmd}" $consume_args "${kafka_topic}" || true; do :
		done;
	} 2>"$consumer_stderr_log"

	"$wait_for_kafka_consumer_ready" "$consumer_stderr_log"

	# Want to expand arguments, so...
	# shellcheck disable=SC2086
	printf '%s\n' "$expected_message" | \
				   "${kafka_cmd}" $produce_args "${kafka_topic}"

	IFS= read -ru "${COPROC[0]}" message

	assertEquals "${expected_message}" "${message}"

	rkill "$COPROC_PID" >/dev/null || true
}
