#!/usr/bin/env bash

# Prozzie - Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018 Wizzie S.L.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Main kafka prozzie CLI entrypoint
# Arguments:
#  [--shorthelp] - Show one line help
#  [-h/--help] - Show help
#
# Environment
#  - PREFIX: Prozzie installation location
#
# Out:
#  UI
#
# Exit status:
#  Subcommand exit status


. "${PREFIX}/share/prozzie/cli/common.bash"

# Main command help
# Arguments:
#  1 - Prefix for subcommand help execution
#
# Environment
#  -
#
# Out:
#  Proper help
#
# Exit status:
#  Always 0
kafka_help () {
    cat <<-EOF
		Prozzie kafka configuration tool.

		Please use some of the following commands:
	EOF

    zz_cli_subcommand_help "$1"
}

# Main cli entrypoint
main () {
    declare prozzie_kafka_cli_prefix
    prozzie_kafka_cli_prefix="${PREFIX}/share/prozzie/cli/prozzie-kafka-"
    declare -r prozzie_kafka_cli_prefix

    if [[ $# == 0 || $1 == --help ]]; then
        kafka_help "$prozzie_kafka_cli_prefix"
        exit 0
    elif [[ $1 == --shorthelp ]]; then
        printf '%s\n' 'Handle or ask prozzie kafka cluster'
        exit 0
    fi


    zz_cli_case "${prozzie_kafka_cli_prefix}" "$@"
}

main "$@"
