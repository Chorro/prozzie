#!/usr/bin/env bash

if [[ ! -v PROZZIE_PREFIX ]]; then
	declare -r PROZZIE_PREFIX=/opt/prozzie/
fi

test_help () {
	# Prozzie must show help with no failure
	"${PROZZIE_PREFIX}/bin/prozzie" >/dev/null 2>&1
	assertTrue $?
}

wait_for_kafka_consumer_ready () {
	while ! grep \
	  'Error while fetching metadata with correlation id.*LEADER_NOT_AVAILABLE' \
	  "$1" >/dev/null; do
	  	:
	 done
}

test_internal_kafka () {
	set -e
	# We should be able to produce & consume from kafka
	declare kafka_topic message COPROC COPROC_PID
	declare -r expected_message='{"my":"message"}'
	kafka_topic=$(mktemp ptXXXXXXXXXX)

	coproc { "${PROZZIE_PREFIX}/bin/prozzie" kafka consume "${kafka_topic}"; } \
							2>consume.stderr;

	wait_for_kafka_consumer_ready consume.stderr

	printf '%s\n' "$expected_message" | \
		"${PROZZIE_PREFIX}/bin/prozzie" kafka produce "${kafka_topic}"

	IFS= read -ru "${COPROC[0]}" message

	assertEquals "${expected_message}" "${message}"

	rkill "$COPROC_PID" >/dev/null
	set +e
}

. /usr/bin/shunit2
