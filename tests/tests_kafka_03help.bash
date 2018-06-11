#!/usr/bin/env bash

. base_tests_kafka.bash

##
## @brief Kafka help should give us a zero exit code, and each of subcommands
##        help
##
test_kafka_help () {
	# Only execute kafka should return OK and show help
	"${PROZZIE_PREFIX}/bin/prozzie" kafka > /dev/null
	"${PROZZIE_PREFIX}/bin/prozzie" kafka --help > /dev/null
}

. test_run.sh
