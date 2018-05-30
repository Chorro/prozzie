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
    for var in "${!module_hidden_envs[@]}"; do
        printf '%s=%s\n' "${var}" "${module_hidden_envs["${var}"]}" >> "$1"
    done

    # Escape dots for app_setup environments
    for var in "${!module_envs[@]}"; do
        if printf '%s' "$var" | grep '\.' >/dev/null; then
           module_envs["${var//./__}"]="${module_envs[$var]}"
           unset -v module_envs[$var]
       fi
    done

    # Ask for regular variables
    ENV_FILE="$1" app_setup --no-reload-prozzie "$@"

    # Undo escape
    inline_awk "$1" -F '=' -v OFS="=" '{ gsub(/__/, ".", $1); }1-2'
}

# Base setup for prozzie apps configured by kafka connect cli (kcli).
# Arguments:
#  1 - properties file to update
#
# Environment:
#  PROZZIE_CLI - prozzie cli binary
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
    log info "These changes will be applied at the end of app setup\n"
    kcli_update_properties_file "$1"
    declare -r module_name="${module_envs['name']-${module_hidden_envs['name']}}"
    "${PROZZIE_CLI}" kcli create "${module_name}" < "$1"
}
