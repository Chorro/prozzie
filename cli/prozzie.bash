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


# We are located in ${PREFIX}/share/prozzie/cli/prozzie.bash, so...
# Resolve symlinks
declare -r my_path=$(realpath "${BASH_SOURCE[0]}")
# Extract prozzie prefix
declare -r PREFIX=${my_path%/share/prozzie/cli/prozzie.bash}

. "${PREFIX}/share/prozzie/cli/common.bash"

# Main case switch in prozzie cli
# Arguments:
#  1 - Prefix to search command
#  2 - Command to execute
#  N - Rest of the options to send to command
#
# Environment
#  -
#
# Out:
#  Error string if cannot find command
#
# Exit status:
#  Subcommand exit status
zz_case () {
    declare -r subcommand="$1$2.bash"
    if [[ ! -x $(realpath "${subcommand}") ]]; then
        "$0: '$1$2' is not a $0 command. See '$0 --help'." >&2
        exit 1
    fi
    shift  2  # Prefix & subcommand
    (export PREFIX; "$subcommand" "$@")
}

# Fill $1 array with available commands
# Arguments:
#  1 - Prefix to search, including folder and file CLI prefix. For example,
#      /usr/local/share/prozzie/cli/prozzie- will return all files matching with
#      /usr/local/share/prozzie/cli/prozzie-* as subcommands, and will assume
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
available_commands () {
    declare -a ret=( "$1"* )

    # Filter prefix and suffix
    ret=( "${ret[@]#$1}" )
    ret=( "${ret[@]%%.bash}" )
    ret=( "${ret[@]#-*}" )

    printf '%s\n' "${ret[@]}"
}

# Main cli help
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
main_help () {
    declare -a main_commands
    readarray -t main_commands < <(available_commands "$1")

    cat <<-EOF
		Welcome to Prozzie CLI interface!

		Please use some of the next options to start using prozzie:
	EOF

    for subcommand in "${main_commands[@]}"; do
        shorthelp=$("${1}${subcommand}.bash" --shorthelp)
        if [[ $? != 0 ]]; then
            continue
        fi
        printf '\t%s\t%s\n' "${subcommand}" "${shorthelp}"
    done
}

# Main cli entrypoint
# Arguments:
#  [-h/--help] - Show help
#
# Environment
#  - PREFIX: Prozzie installation location
#
# Out:
#  Help or subcommand output
#
# Exit status:
#  Subcommand exit status
main () {
    declare -r prozzie_cli_prefix="${PREFIX}/share/prozzie/cli/prozzie-"

    if [[ $# == 0 || $1 == '-h' || $1 == '--help' ]]; then
        main_help "${prozzie_cli_prefix}"
        exit 0
    fi

    zz_case "${prozzie_cli_prefix}" "$@"
}

main "$@"
