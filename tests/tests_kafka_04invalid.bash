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
