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
## @brief      Show a kafka connect message error indicating how to configure
##             kafka connect modules properly.
##
## @return     Always error.
## @todo       Wrap kcli properly
##
zz_connector_set_variables () {
    {
        printf 'Please use next commands in order to '
        printf 'configure %s:\n' "${module}"
        printf 'prozzie kcli rm %s\n' "${module}"
        printf 'prozzie config setup %s\n' "${module}"
    } >&2

    return 1
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

    # Get properties for hint message
    kcli_fill_module_envs "$module"
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

    # Get properties for hint message
    kcli_fill_module_envs "$module"
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

kcli_fill_module_envs () {
	declare -r module="$1" output_filename='/dev/null'

	zz_variables_env_update_array <("${PREFIX}/bin/prozzie" kcli get "$module" \
															| sed 's/\./__/g') \
								  "${output_filename}"
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
        printf '%s=%s\n' "${var}" "${module_hidden_envs["${var}"]}" >> "$1"
    done

    # Escape dots for app_setup environments
    for var in "${!module_envs[@]}"; do
        if printf '%s' "$var" | grep '\.' >/dev/null; then
           module_envs["${var//./__}"]="${module_envs[$var]}"
           unset -v "module_envs[$var]"
       fi
    done

    # Ask for regular variables
    declare -r temp_env_file="$1"
    connector_setup --no-reload-prozzie "$temp_env_file" "$@"

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
    log info 'These changes will be applied at the end of app setup\n'
    kcli_update_properties_file "$1"
    declare -r module_name="${module_envs['name']-${module_hidden_envs['name']}}"
    "${PREFIX}/bin/prozzie" kcli create "${module_name}" < "$1"
}
