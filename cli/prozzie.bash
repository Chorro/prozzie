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
my_path=$(realpath "${BASH_SOURCE[0]}")
declare -r my_path
# Extract prozzie prefix
declare -r PREFIX=${my_path%/share/prozzie/cli/prozzie.bash}

# Include common functions
. "${PREFIX}/share/prozzie/cli/include/common.bash"
. "${PREFIX}/share/prozzie/cli/include/cli.bash"

# Prozzie cli help
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
    cat <<-EOF
		Welcome to Prozzie CLI interface!

		Please use some of the next options to start using prozzie:
	EOF

    zz_cli_subcommand_help "$1"
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
    if [[ "$1" == '--version' || $1 == '-v' ]]; then
        printf "Prozzie - Wizzie Data Platform (WDP) main entrypoint\\nVersion: %s\\n" "$(<"${PREFIX}/etc/prozzie/.version")"
        exit 0
    fi

    declare -r prozzie_cli_prefix="${PREFIX}/share/prozzie/cli/prozzie-"

    if [[ $# == 0 || $1 == '-h' || $1 == '--help' ]]; then
        main_help "${prozzie_cli_prefix}"
        exit 0
    fi

    zz_cli_case "${prozzie_cli_prefix}" "$@"
}

main "$@"
