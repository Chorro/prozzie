#!/usr/bin/env bash

. base_tests_kafka.bash

##
## @brief Test kafka topics command
##
test_kafka_topics () {
	declare topic
	topic=$(new_random_topic)

	# Check that topic does not exists
	if "${PROZZIE_PREFIX}/bin/prozzie" kafka topics --list | grep -- "$topic"; then
		${_FAIL_} "'Topic $topic does exist before of testing'"
	fi

	# Create topic with two partitions
	"${PROZZIE_PREFIX}/bin/prozzie" kafka topics --create \
	    --replication-factor 1 --partitions 2 --topic "$topic"

	# It exists and it have 2 partitions
	"${PROZZIE_PREFIX}/bin/prozzie" kafka topics --list | grep -- "$topic"
	"${PROZZIE_PREFIX}/bin/prozzie" kafka topics --describe \
	    | grep -- '^Topic:'"$topic"$'\tPartitionCount:2'

	# We are able to produce to each partition
	printf '%s\n' '{"p":0}' | kafkacat -b localhost:9092 -t "$topic" -p 0
	printf '%s\n' '{"p":1}' | kafkacat -b localhost:9092 -t "$topic" -p 1

	# And unable to produce to inexistent partition
	if printf '%s\n' '{"p":1}' | kafkacat -b localhost:9092 -t "$topic" -p 2; then
		${_FAIL_} "'Can produce to unknown partition'"
	fi
}

. test_run.sh
