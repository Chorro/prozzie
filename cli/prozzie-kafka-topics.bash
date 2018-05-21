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

# Main kafka subcommands entrypoint
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

. "${BASH_SOURCE%/*}/include/common.bash"
. "${BASH_SOURCE%/*}/include/cli.bash"

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
    declare -r -a omit_parameters_arr=(
        zookeeper broker-list bootstrap-server new-consumer)

    declare omit_parameters
    omit_parameters=$(str_join '|' "${omit_parameters_arr[@]}")
    declare -r omit_parameters

    declare -r print_headers_awk="NR==2 {RS=\"\\n--\"} NR<=3 {print \$0; next}"
    # Set this record separator   ^^^^^^^^^^^^^^^^^^^
    # only after the 3rd line
    # Skip help and table header                       ^^^^^^^^^^^^^^^^^^^^^^^
    declare -r print_arguments_awk="!/^(${omit_parameters})/ {print \"--\"\$0}"
    # Filter out the unwanted help    ^^^^^^^^^^^^^^
    # parameters

    awk "${print_headers_awk} ${print_arguments_awk}"
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
#  -
# Environment
#  -
#
# Out
#  UX message
ux_print () {
    declare first_character first_line print_callback
    read -r -n 1 first_character
    if [[ "$first_character" == '>' ]]; then
        # We are waiting for user input, so just print every character until end
        printf '%s' "$first_character"
        cat -
        return
    fi

    first_line="${first_character}$(head -n 1 -)"
    case "$first_line" in
        'Command must include exactly one action:'*| \
        'Exactly one of whitelist/topic is required.'*| \
        'Missing required argument'*| \
        *'is not a recognized option'*)
            print_callback=ux_print_help_options
            ;;
        'Exception in thread'*)
            print_callback=ux_print_java_exception
            ;;
        *)
            # Last resort
            print_callback='cat'
            ;;
    esac

    cat <(printf '%s\n' "$first_line") - | "$print_callback"
}

# Execute the given kafka container script located in /opt/kafka/.sh script
# located in the container, forwarding all arguments and adding proper options
# if needed.
# Arguments
#  1 - The container command to execute
#  N - The container binary arguments
#
# Environment
#  cmd_default_parameters - Use this parameters if they are not found in the cmd
#  line.
#
# Out
#  UX message
#
container_kafka_exec () {
    declare -a prozzie_params
    declare -r container_bin="$1"
    shift

    for arg in "${!cmd_default_parameters[@]}"; do
        prozzie_params+=("$arg")
        prozzie_params+=("${cmd_default_parameters[$arg]}")
    done

    "${PREFIX}/bin/prozzie" compose exec -T kafka \
            "/opt/kafka/bin/${container_bin}" "${prozzie_params[@]}" "$@" \
            | ux_print
}

# Prepare kafka container command server parameter.
# Arguments
#  1 - The parameter that uses the command to identify server
#  2 - The port of the parameter value
#  N - Provided binary arguments
#
# Environment
#  cmd_default_parameters - The associative array that will be filled with
#  server parameter
#
# Out
#  -
#
prepare_cmd_default_server () {
    declare server_host
    declare -r server_parameter="$1"
    declare -r server_port="$2"
    shift 2

    if ! array_contains "${server_parameter}" "$@"; then
        server_host="$("${PREFIX}/bin/prozzie" config base INTERFACE_IP)"
        cmd_default_parameters["$server_parameter"]="${server_host}:${server_port}"
    fi
}

# Main kafka subcommands entrypoint
main () {
    if [[ "$1" == '--shorthelp' ]]; then
        printf '%s\n' 'Handle or ask kafka cluster'
        exit 0
    fi

    declare -g -A cmd_default_parameters

    declare my_name container_bin server_parameter server_port
    my_name=$(basename -s '.bash' "$0")
    declare -r my_tail="${my_name##*-}"

    case "${my_tail}" in
    topics)
        container_bin='kafka-topics.sh'
        server_parameter='--zookeeper'
        ;;
    produce|consume)
        if [[ $# -gt 0 && "$1" != "--"* ]]; then
            # The first argument is topic
            cmd_default_parameters['--topic']="$1"
            shift
        fi
        ;;&
    produce)
        container_bin='kafka-console-producer.sh'
        server_parameter='--broker-list'
        ;;
    consume)
        container_bin='kafka-console-consumer.sh'

        if array_contains '--zookeeper' "$@"; then
            server_parameter='--zookeeper'
        else
            server_parameter='--bootstrap-server'
        fi

        if [[ $# -gt 0 && "$1" != "--"* ]]; then
            # The second argument is partition
            cmd_default_parameters['--partition']="$1"
            shift
        fi
        ;;
    *)
        log error "Unknown subcommand ${my_tail}.\\n"
        exit 1
    esac

    if [[ "${server_parameter}" == '--zookeeper' ]]; then
        server_port=2181
    else
        server_port=9092
    fi

    prepare_cmd_default_server "${server_parameter}" "${server_port}"
    container_kafka_exec "${container_bin}" "$@"
}

main "$@"
