#!/usr/bin/env bash

. "${PROZZIE_PREFIX}/share/prozzie/cli/include/common.bash"
. base_tests_kafka.bash

##
## @brief Invalid kafka parameters tests
##
test_kafka_invalid_action_parameter () {
	declare out errout
	tmp_fd out
	tmp_fd errout

	for action in invalid consume produce topics; do
		for parameter in '' '--invalid'; do
			# Only execute kafka should return not OK and output help
			if "${PROZZIE_PREFIX}/bin/prozzie" kafka "$action" $parameter \
													> "/dev/fd/${out}" \
		                                            2> "/dev/fd/${errout}"; then
		        ${_FAIL_} "'Kafka invalid action returns success'"
		    fi
			# Sometimes it has a newline
			[[ "$(wc -c < "/dev/fd/${out}")" -lt 2 ]]
			assertNotEquals '0' "$(wc -c < "/dev/fd/${errout}")"
			assert_no_kafka_server_parameter < "/dev/fd/${errout}"
		done
	done

}

. test_run.sh
