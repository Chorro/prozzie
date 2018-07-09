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

# Main case switch in prozzie cli
# Arguments:
#  1 - Prefix to search command
#  2 - Command to execute
#  N - Rest of the options to send to command
#
# Environment
#  PREFIX - Prozzie installation location
#
# Out:
#  Error string if cannot find command
#
# Exit status:
#  Subcommand exit status
zz_cli_case () {
    declare -r subcommand="$1$2.bash"
    if [[ ! -x $(realpath "${subcommand}") ]]; then
        "$0: '$1$2' is not a $0 command. See '$0 --help'." >&2
        exit 1
    fi
    shift  2  # Prefix & subcommand

    # Use a subshell to avoid propagate subcommand changes
    # shellcheck disable=SC2030
    (export PREFIX; "$subcommand" "$@")
}

# Return a newline separated array with available commands.
#
# Arguments:
#  1 - Prefix to search, including folder and file CLI prefix. For example,
#      /share/prozzie/cli/prozzie- will return all files matching with
#      /share/prozzie/cli/prozzie-* as subcommands, and will assume
#      prozzie-test-1 and prozzie-test-2 as the same command (test).
#
# Environment
#  -
#
# Out:
#  Newline separated subcommands
#
# Exit status:
#  -
zz_cli_available_commands () {
    declare -a ret=( "$1"* )

    # Filter prefix and suffix
    ret=( "${ret[@]#$1}" )
    ret=( "${ret[@]%%.bash}" )
    ret=( "${ret[@]%-*}" )

    # Delete duplicates
    read -d '' -r -a ret <<< "$(printf '%s\n' "${ret[@]}" | sort -u)"

    printf '%s\n' "${ret[@]}"
}

# Prozzie cli subcommands help
# Arguments:
#  1 - Prefix for subcommand help execution
#
# Environment
#  subcommands_help - This associative array will be printed before of the
#                     subcommands if it exists.
#
# Out:
#  Proper help
#
# Exit status:
#  Always 0
zz_cli_subcommand_help () {
    declare -a subcommands
    declare subcommand shorthelp

    readarray -t subcommands < <(zz_cli_available_commands "$1")

    for subcommand in "${subcommands[@]}"; do
        # We want PREFIX export only in the subcommand
        # shellcheck disable=SC2031
        shorthelp=$(export PREFIX; "${1}${subcommand}.bash" --shorthelp)
        printf '\t%s\t%s\n' "${subcommand}" "${shorthelp}"
    done
}

##
## @brief      Determines if it exists key in module_envs associative array.
## @example    if exists_key_in_module_envs kafka_topic; then echo "T"; fi
##
## @note       Can't accept array name as parameters because centos' bash4.2
##             does not support dereference it that way.
##
## @param      Key to find in module_envs array
##
## @return     True if exists key, False otherwise.
##
exists_key_in_module_envs () {
    needle="$1"
    [[ "${module_envs[$needle]+_}" ]]
}

# Apply a format with 40 spaces between command and its description
#
# Arguments
#  1 - Command to describe
#  2 - Description of command
#
# Environment
#  -
#
# Out:
#  Formated string
#
# Return code
#  Always 0
apply_help_command_format () {
    printf '\t%-45s%s\n' "$1" "$2"
}
