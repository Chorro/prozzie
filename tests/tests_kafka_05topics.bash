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
