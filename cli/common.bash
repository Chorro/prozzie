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

# ZZ variables treatment. Checks if an environment variable is defined, and ask
# user for value if not.
# After that, save it in docker-compose .env file
# Arguments:
#  [--env-file] env file to write (default to $PREFIX/prozzie/.env)
#  $1 The variable name. Will be overridden if needed.
#  $2 Default value if empty text introduced ("" for error raising)
#  $3 Question text
#
# Environment:
#  -
#
# Out:
#  User Interface
#
# Exit status:
#  Always 0
zz_variable () {
  if [[ $1 == --env-file=* ]]; then
    local readonly env_file="${1#--env-file=}"
    shift
  else
    local readonly env_file="$PREFIX/etc/prozzie/.env"
  fi

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
# variable it's not contained in $2, copy it to .env file
# Arguments:
#  $1 source .env file
#  $2 destination .env file
#  $3 Array to update
function zz_variables_env_update_array {
  # TODO: bash >4.3, proper way is [local -n zz_vars_array=$3]. Alternative:
  eval "declare -A zz_vars_array="${3#*=}

  while IFS='=' read -r var_key var_val || [[ -n "$var_key" ]]; do
    if [ ${zz_vars_array[$var_key]+_} ]; then
      # Update zz variable
      local readonly prompt=$(cut -d '|' -f 2 <<< ${zz_vars_array[$var_key]})
      zz_vars_array[$var_key]=$(printf "%s|%s" "$var_val" "$prompt")
    else
      # Copy to output .env file
      printf "%s=%s\n" "$var_key" "$var_val" >> "$2"
    fi
  done < "$1"

  # TODO bash >4.3 hack. We don't need this with bash>4.3
  local -r ret="$(declare -p zz_vars_array)"
  printf "%s" "${ret#*=}"
}

# Ask user for a single ZZ variable
# Arguments:
#  $1 env file to save variables
#  $2 Array with variables
#  $3 Variable to ask user for
# Notes:
#  - If environment variable is defined, user will not be asked for value
function zz_variable_ask {
  local var_default
  local var_prompt
  # TODO: When bash >4.3, proper way is [local -n var_array=$2]. Alternative:
  eval "declare -A var_array="${2#*=}

  IFS='|' read var_default var_prompt <<< "${var_array[$3]}"
  zz_variable --env-file="$1" "$3" "$var_default" "$var_prompt"
}

# Ask user for ZZ module variables
# Arguments:
#  $1 env file to save variables
#  $2 Array with variables
function zz_variables_ask {
  # TODO: When bash >4.3, proper way is [local -n zz_variables=$2]. Alternative:
  eval "declare -A zz_variables="${2#*=}

  for var_key in "${!zz_variables[@]}"; do
    # TODO: When bash >4.3, proper way is [zz_variable_ask "$1" $2 "$var_key"]. Alternative:
    zz_variable_ask "$1" "$(declare -p zz_variables)" "$var_key"
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
# Needs a declared "module_envs" global array:
# ([global_var]="default|description")
# Arguments:
#  [--no-reload-prozzie] Don't reload prozzie at the end of call.
app_setup () {
  declare reload_prozzie=y
  if [[ $1 == --no-reload-prozzie ]]; then
    reload_prozzie=n
    shift
  fi

  if [[ ! -z ${ENV_FILE+x} ]]; then
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
  # TODO all the `$(declare -p module_envs)` are just a hack in order to
  # support old bash versions (<4.3, Centos 7 case), same with returning
  # and re-declaring it. With bash `4.3`. Proper way to do is to pass the
  # array variable, and use `local -n`.
  eval 'declare -A module_envs='$(zz_variables_env_update_array \
                                                    "$src_env_file"\
                                                    "/dev/fd/${mod_tmp_env}"\
                                                    "$(declare -p module_envs)")
  zz_variables_ask "/dev/fd/${mod_tmp_env}" "$(declare -p module_envs)"

  # Hurray! app installation end!
  cp "/dev/fd/${mod_tmp_env}" "$src_env_file"
  exec {mod_tmp_env}<&-
  trap '' EXIT

  # Reload prozzie
  if [[ $reload_prozzie == y ]]; then
    "${src_env_file%etc/prozzie/.env}/bin/prozzie" up -d
  fi
}
