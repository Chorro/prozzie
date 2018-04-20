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

# Main cli entrypoint
# Arguments:
#  [--shorthelp] - Show one line help
#  [-h/--help] - Show help
#
# Environment
#  - PREFIX: The prozzie installation location
#
# Out:
#  The help or subcommand output
#
# Exit status:
#  The Subcommand exit status

. "${PREFIX}/share/prozzie/cli/common.bash"
declare -r env_file="${PREFIX}/etc/prozzie/.env"

# Print kafka argument list in a user-friendly way. Use stdin to provide Kafka
# argument.
#
# Arguments
#  -
#
# Environment
#  -
#
# Out
#  UX message
#
ux_print_help_options () {
    awk 'NR==2 {RS="\n--"} NR<=3 {print $0; next} !/^zookeeper/ {print "--"$0}'
    #    ^^^^^^^^^^^^^^^^^- Set this record separator only after the 3rd line
    #                      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Skip help and table header
    #          Filter out zookeeper help command ^^^^^^^^^^^^
}

# Print kafka exception in an user friendly way. Use stdin to provide Kafka
# exception.
#
# Arguments
#  1 - kafka*.sh out file
#
# Environment
#  -
#
# Out
#  UX message
#
ux_print_java_exception () {
    grep 'Exception in thread\|Caused by' | cut -d ':' -f 2-
}

# Filter complicated kafka output and filter-out connection hidden stuff
# Arguments
#  $1 - kafka command output
ux_print () {
    declare first_line
    first_line=$(head -n 1 "$1")

    case "$first_line" in
        'Command must include exactly one action:'*| \
        'Missing required argument'*)
            ux_print_help_options < "$1"
            ;;
        'Exception in thread'*)
            ux_print_java_exception < "$1"
            ;;
        *)
            cat "$1"  # Last resort
    esac
}

# Execute the kafka_topics.sh script located in the container, forwarding all
# arguments and adding proper "--zookeeper" if needed.
container_kafka_topics () {
    # Externally given zookeeper
    declare param zookeeper_args
    declare zookeeper_in_params=n
    declare zookeeper_host
    declare topics_out
    for param in "$@"; do
        if [[ "$param" == --zookeeper ]]; then
            zookeeper_in_params=y
            break;
        fi
    done

    if [[ "$zookeeper_in_params" == n ]]; then
        declare -g -A module_envs=([INTERFACE_IP]='')
        zz_variables_env_update_array "$env_file" /dev/null
        # Trim last pipe that difference between variable and prompt
        zookeeper_host="${module_envs[INTERFACE_IP]%|*}"
        zookeeper_args=('--zookeeper' "${zookeeper_host}:2181")
        unset -v module_envs
    fi

    tmp_fd topics_out
    "${PREFIX}/bin/prozzie" compose exec kafka \
            /opt/kafka/bin/kafka-topics.sh "${zookeeper_args[@]}" "$@" \
            > "/dev/fd/${topics_out}"
    ux_print "/dev/fd/${topics_out}"
}

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
kafka_topic_help () {
    container_kafka_topics
}

# Main kafka topics entrypoint
main () {
    if [[ "$1" == '--shorthelp' ]]; then
        printf '%s\n' 'Handle or ask kafka cluster'
        exit 0
    fi

    container_kafka_topics "$@"
}

main "$@"
