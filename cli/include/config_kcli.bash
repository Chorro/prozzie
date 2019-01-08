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


# This file contains the module functionality to handle compose connectors. If a
# connector is based on a compose file yaml, should include this file and update
# functions accordilly

# This file handles the connectors based on docker compose, and defines the
# functions needed to use them.

##
## @brief      Get kafka connect connector variables, using kcli container for
##             kafka connect modules. Variables will be printed via stdout.
##
## @param      1 - Module name to ask kafka connect for.
## @param      @ - Keys to ask for. If empty, all keys=values will be returned.
##
## @return     kcli get "module" return code.
##
zz_connector_get_variables () {
	declare -r module="$1"
	shift

	if [[ $# -eq 0 ]]; then
            "${PREFIX}"/bin/prozzie kcli get "$module"
            return $?
    fi

    declare vars
    vars=$(str_join '|' "$@")
    declare -r vars

    "${PREFIX}"/bin/prozzie kcli get "$module"|grep -P "^(${vars})=.*$"|while read -r line; do printf '%s\n' "${line#*=}"; done
}

##
## @brief      Set a kafka-connect connector variables
##
## @param [--dry-run] Do not modify any variable
## @param [--no-reload-prozzie] Unused, only for prozzie compose connector
##                              compatibility
## @param 1 Prozzie connector name
## @param @ Variables to set in variable=value format
##
## @return True if variables set or --dry-run, false otherwise
##
zz_connector_set_variables () {
    eval set -- "$(getopt -o '' --long dry-run,no-reload-prozzie -- "$@")"
    declare -a args variables
    declare i properties dry_run=n

    while [[ $1 == '--'* ]]; do
        if [[ $1 == '--no-reload-prozzie' || $1 == -- ]]; then
            # Not related here
            shift
            continue
        elif [[ $1 == '--dry-run' ]]; then
            dry_run=y
        fi
        args+=("$1")
        shift
    done

    declare -r module="$1" dry_run
    shift

    tmp_fd properties
    if [[ $dry_run == n ]]; then
        declare -r prozzie_cmd="${PREFIX}/bin/prozzie"
    else
        # Do not execute actual commands
        declare -r prozzie_cmd=:
    fi

    # Escape variable arguments
    for (( i=1; i<=$#; ++i )); do
        declare key="${!i%%=*}" value="${!i#*=}"
        variables+=("${key/./__}=${value}")
    done

    "$prozzie_cmd" kcli rm "$module"
    kcli_update_properties_file "/dev/fd/${properties}" \
        zz_set_vars "${args[@]}" "/dev/fd/${properties}" "${variables[@]}" \
        | sed ':x; /.*__.*=/ s/__/./; tx' && \
    "$prozzie_cmd" kcli create "${module}" < "/dev/fd/${properties}"
}

##
## @brief      Wrapper for connector_setup, that ask the user for the different
##             variables needed for the connector, and configure it using kcli.
##
zz_connector_setup () {
	declare properties module="$1"

    tmp_fd properties
    kcli_setup "/dev/fd/${properties}" "$module"
    exec {properties}<&-
}

zz_connector_enable () {
	declare -r module="$1"
	declare connector_status
    connector_status=$(kafka_connector_status "$module")
    declare -r connector_status
	case $connector_status in
        PAUSED)
            "${PREFIX}"/bin/prozzie kcli resume "$module" >/dev/null
            printf 'Module %s enabled\n' "$module" >&2
        ;;
        RUNNING)
            printf 'Module %s already enabled\n' "$module" >&2
        ;;
        *)
            "${PREFIX}"/bin/prozzie config setup "$module"
            printf 'Module %s enabled\n' "$module" >&2
        ;;
    esac
}

zz_connector_disable () {
	declare -r module="$1"
	declare connector_status
    connector_status=$(kafka_connector_status "$module")
    declare -r connector_status

	case $connector_status in
        PAUSED)
            printf 'Module %s already disabled\n' "$module" >&2
        ;;
        RUNNING)
            "${PREFIX}"/bin/prozzie kcli pause "$module" >/dev/null
            printf 'Module %s disabled\n' "$module" >&2
        ;;
        *)
            printf "Module %s doesn't exist: connector isn't created"'\n' "$module" >&2
            exit 1
        ;;
    esac
}

kafka_connector_status () {
	"${PREFIX}"/bin/prozzie kcli status "$module" | head -n 1 | grep -o 'RUNNING\|PAUSED'
}

# Calls awk and replace file
# Arguments:
#  1 - input/output file
#  2..n - Arguments to awk
#
# Environment:
#  None
#
# Out:
#  Awk out
#
# Exit status:
#  Awk exit status
inline_awk () {
    # Warning: Do NOT change awk input redirection: it will get messy if you try
    # to tell awk to read from '/dev/fd/*'
    local -r file_name="$1"
    shift
    declare inline_awk_temp
    tmp_fd inline_awk_temp
    awk "$@" < "${file_name}" > "/dev/fd/${inline_awk_temp}"
    rc=$?
    cp -- "/dev/fd/${inline_awk_temp}" "${file_name}"
    exec {inline_awk_temp}<&-
    return $rc
}

# Update kcli properties file
# Arguments:
#  1 - properties file to update
#  2 - Callback to update
#  @ - Arguments to callback
#
# Environment:
#  module_envs - Variables to ask via app_setup.
#  module_hidden_envs - Variables to add to base file if it is not defined. If
#    some variable is already defined, it will NOT be override.
#
# Out:
#  User interface
#
# Exit status:
#  Regular
kcli_update_properties_file () {
    declare line var

    # Delete variables already included in file.
    while IFS='' read -r line || [[ -n "$line" ]]; do
        var="${line#*=}"
        unset -v module_hidden_envs["$var"] 2>/dev/null
    done < "$1"

    # Write variables not present in file
    # shellcheck disable=SC2154
    for var in "${!module_hidden_envs[@]}"; do
        # shellcheck disable=SC2154
        printf '%s=%s\n' "${var}" "${module_hidden_envs[${var}]%%|*}" >> "$1"
    done

    # Escape dots for app_setup environments
    for var in "${!module_envs[@]}"; do
        if printf '%s' "$var" | grep '\.' >/dev/null; then
           module_envs["${var//./__}"]="${module_envs[$var]}"
           unset -v "module_envs[$var]"
       fi
    done

    "${@:2}"  # Callback to update variables

    # Undo escape
    inline_awk "$1" -F '=' -v OFS='=' '{ gsub(/__/, ".", $1); }1-2'
}

# Base setup for prozzie apps configured by kafka connect cli (kcli). It will
# never reload prozzie
# Arguments:
#  1 - properties file to update
#
# Environment:
#  PREFIX - prozzie prefix
#  module_envs - Variables to ask via app_setup.
#  module_hidden_envs - Variables to add to base file if it is not defined. If
#    some variable is already defined, it will NOT be override.
#
# Out:
#  User interface
#
# Exit status:
#  Regular
kcli_setup () {
    log info $'These changes will be applied at the end of app setup\n'

    # Ask for regular variables
    declare -r temp_env_file="$1"
    connector_env_file() { printf '%s\n' "$temp_env_file"; }

    declare module_name="${module_envs['name']-${module_hidden_envs['name']}}"
    # Only the name, not the module prompt or help
    module_name="${module_name%%|*}"
    kcli_update_properties_file "$1" connector_setup "${module_name}"
    "${PREFIX}/bin/prozzie" kcli create "${module_name}" < "$1"
}
