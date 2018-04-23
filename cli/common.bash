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


# Text colors
readonly red="\e[1;31m"
readonly green="\e[1;32m"
readonly yellow="\e[1;33m"
readonly white="\e[1;37m"
readonly normal="\e[m"

readonly DEFAULT_PREFIX="/usr/local"

# log function
function log {
  case $1 in
    e|error|erro) # ERROR
      printf "[ ${red}ERRO${normal} ] $2"
      ;;
    i|info) # INFORMATION
      printf "[ ${white}INFO${normal} ] $2"
    ;;
    w|warn) # WARNING
      printf "[ ${yellow}WARN${normal} ] $2"
    ;;
    f|fail) # FAIL
      printf "[ ${red}FAIL${normal} ] $2"
    ;;
    o|ok) # OK
      printf "[  ${green}OK${normal}  ] $2"
    ;;
    *) # USAGE
      printf "Usage: log [i|e|w|f] <message>"
    ;;
  esac
}

# Check function $1 existence
function func_exists {
    declare -f "$1" > /dev/null
    return $?
}

command_exists () {
    command -v "$1" 2>/dev/null
}

# Read a y/n response and returns true if answer is yes
read_yn_response () {
    local reply;
    read -p "$1 [Y/n]: " -n 1 -r reply
    if [[ ! -z $reply ]]; then
        printf '\n'
    fi

    [[ -z $reply || $reply == 'y' || $reply == 'Y' ]]
}

# Creates a temporary unnamed file descriptor that you can use and it will be
# deleted at shell exit (on close). File descriptor will be saved in $1 variable
# Arguments:
#  1 - Variable to save newly created temp file descriptor
tmp_fd () {
    declare -r file_name=$(mktemp)
    eval "exec {$1}>${file_name}"
    rm "${file_name}"
}

# Reads user input, using readline completions interface to fill paths.
# Arguments:
#  $1 - Variable to store user introduced text
#  $2 - Prompt to user
#  $3 - Default answer (optional)
zz_read_path () {
    read -e -i "$3" -r -p "$2: " "$1"
}

# Reads user input, forbidding tab (or other keys) completions but enabling
# the rest of readline features, like navigate through arrow keys
# Arguments:
#  $1 - Variable to store user introduced text
#  $2 - Prompt to user
#  $3 - Default answer (optional)
zz_read () {
    read -r "$1" < <(
        # Process substitution avoids overriding complete un-binding. Another
        # way, exiting with Ctrol-C would cause binding ruined.
        bind -u 'complete' 2>/dev/null
        zz_read_path "$1" "$2" "$3" >/dev/tty
        printf '%s' "${!1}"
    )
}

# Check if an array contains a particular element
#
# Arguments:
#  1 - Element to find
#  N - Array passed as "${arr[@]}"
#
# Out:
#  None
#
# Return:
#  True if found, false other way
array_contains () {
    declare -r needle="$1"
    shift

    for element in "$@"; do
        if [[ "${needle}" == "${element}" ]]; then
            return 0
        fi
    done

    return 1
}


# Print a string which is the concatenation of the strings in parameters >1. The
# separator between elements is $1.
#
# Arguments
#  1 - The Token to use to join (can be empty, '')
#  N - The strings to join
#
# Environment
#  -
#
# Out:
#  Joined string
#
# Return code
#  Always 0
str_join () {
    declare ret
    declare -r join_str="$1"
    shift

    while [[ $# -gt 0 ]]; do
        ret+="$1"
        if [[ $# -gt 1 ]]; then
            ret+="$join_str"
        fi

        shift
    done

    printf '%s\n' "$ret"
}

# ZZ variables treatment. Checks if an environment variable is defined, and ask
# user for value if not.
# After that, save it in docker-compose .env file
# Arguments:
#  $1 The variable name. Will be overridden if needed.
#  $2 Default value if empty text introduced ("" for error raising)
#  $3 Question text
#  $4 env file to write
# Environment:
#  module_envs - Associated array to update.
#
# Out:
#  User Interface
#
# Exit status:
#  Always 0
zz_variable () {
  declare -r env_file="$4"

  if [[ "$1" == PREFIX || "$1" == *_PATH ]]; then
    declare -r read_callback=zz_read_path
  else
    declare -r read_callback=zz_read
  fi

  while [[ -z "${!1}" ]]; do
    "$read_callback" "$1" "$3" "$2"

    if [[ -z "${!1}" && -z "$2" ]]; then
      log fail "[${!1}][$2] Empty $1 not allowed"'\n'
    fi
  done

  if func_exists "$1_sanitize"; then
    read -r $1 <<< "$($1_sanitize "${!1}")"
  fi

  if [[ $1 != PREFIX ]]; then
    printf "%s=%s\n" "$1" "${!1}" >> "$env_file"
  fi
}

# Update zz variables array default values using a docker-compose .env file. If
# variable it's not contained in module_envs, copy it to .env file
# Arguments:
#  1 - File to read previous values
#  2 - File to save not-interesting values
#
# Environment:
#  module_envs - Associated array to update and iterate searching for variables
#
# Out:
#  -
#
# Exit status:
#  Always 0
zz_variables_env_update_array () {
  while IFS='=' read -r var_key var_val || [[ -n "$var_key" ]]; do
    if [ ${module_envs[$var_key]+_} ]; then
      # Update zz variable
      declare -r prompt=$(cut -d '|' -f 2 <<< "${module_envs[$var_key]}")
      module_envs[$var_key]=$(printf "%s|%s" "$var_val" "$prompt")
    else
      # Copy to output .env file
      printf "%s=%s\n" "$var_key" "$var_val" >> "$2"
    fi
  done < "$1"
}

# Ask user for a single ZZ variable. If the environment variable is defined,
# assign the value to the variable directly.
# Arguments:
#  $1 The env file to save variables
#  $2 The variable to ask user for
#
# Environment:
#  module_envs - The associated array to update.
#
# Out:
#  User Interface
#
# Exit status:
#  Always 0
zz_variable_ask () {
    local var_default
    local var_prompt

    IFS='|' read -r var_default var_prompt <<< "${module_envs[$2]}"
    zz_variable "$2" "$var_default" "$var_prompt" "$1"
}

# Ask the user for module variables. If the environment variable is defined,
# assign the value to the variable directly.
# Arguments:
#  $1 The env file to save variables
#
# Environment:
#  module_envs - The associated array to update.
#
# Out:
#  User Interface
#
# Exit status:
#  Always 0
zz_variables_ask () {
    for var_key in "${!module_envs[@]}"; do
        zz_variable_ask "$1" "$var_key"
    done
}

# Print a warning saying that "$src_env_file" has not been modified.
# Arguments:
#  -
#
# Environment:
#  src_env_file - Original file to print in warning. It will print no message if
#  it does not exist or if it is under /dev/fd/.
#
# Out:
#  -
#
# Exit status:
#  Always 0
print_not_modified_warning () {
    echo
    if [[ "$src_env_file" != '/dev/fd/'* && -f "$src_env_file" ]]; then
        log warn "No changes made to $src_env_file"'\n'
    fi
}

# Set up appliction in prozzie
# Arguments:
#  [--no-reload-prozzie] Don't reload prozzie at the end of `.env` changes
#
# Environment:
#  ENV_FILE - The path of `.env` file to modify
#  src_env_file - ENV_FILE Backup. Variable will be unset after function call.
#    See print_not_modified_warning.
#  DEFAULT_PREFIX - (see common.bash:DEFAULT_PREFIX)
#  PREFIX - Where to look for the `.env` file. Defaults to DEFAULT_PREFIX
#  module_envs - The variables to ask for, in form:
#    ([global_var]="default|description"). See also
#    `zz_variables_env_update_array` and `zz_variables_ask`
#
# Out:
#  User interface
#
# Exit status:
#  Always 0
app_setup () {
  declare reload_prozzie=y
  if [[ $1 == --no-reload-prozzie ]]; then
    reload_prozzie=n
    shift
  fi

  if [[ -v ENV_FILE ]]; then
    src_env_file="${ENV_FILE}"
  else
    src_env_file="${PREFIX:-${DEFAULT_PREFIX}}/etc/prozzie/.env"
  fi

  while [[ ! -f "$src_env_file" ]]; do
    zz_read_path src_env_file \
        ".env file not found. Please provide .env path" \
        "$src_env_file"
  done

  declare mod_tmp_env
  tmp_fd mod_tmp_env
  trap print_not_modified_warning EXIT

  # Check if the user previously provided the variables. In that case,
  # offer user to mantain previous value.
  zz_variables_env_update_array "$src_env_file" "/dev/fd/${mod_tmp_env}"
  zz_variables_ask "/dev/fd/${mod_tmp_env}"

  # Hurray! app installation end!
  cp "/dev/fd/${mod_tmp_env}" "$src_env_file"
  exec {mod_tmp_env}<&-
  trap '' EXIT

  # Reload prozzie
  if [[ $reload_prozzie == y ]]; then
    "${src_env_file%etc/prozzie/.env}/bin/prozzie" up -d
  fi

  unset -v src_env_file
}

#
# CLI
#

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
        shorthelp=$(export PREFIX; "${1}${subcommand}.bash" --shorthelp)
        printf '\t%s\t%s\n' "${subcommand}" "${shorthelp}"
    done
}
