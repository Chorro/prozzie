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


function ZZ_HTTP_ENDPOINT_sanitize() {
  declare out="$1"
  if [[ ! "$out" =~ ^http[s]?://* ]]; then
    declare out="https://${out}"
  fi
  if [[ ! "$out" =~ /v1/data[/]?$ ]]; then
    declare out="${out}/v1/data"
  fi
  printf "%s" "$out"
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
  declare prompt
  while IFS='=' read -r var_key var_val || [[ -n "$var_key" ]]; do
    if [ ${module_envs[$var_key]+_} ]; then
      # Update zz variable
      declare prompt=$(cut -d '|' -f 2 <<< "${module_envs[$var_key]}")
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

zz_describe_variables () {
    declare key value
    for key in "${!module_envs[@]}"; do
        value=${module_envs[$key]}
        IFS='|' read value _ <<< "${value}" # Using '_' as ignore symbol
        printf '%s: %s' "$key" "$value"
    done
}

show_variables() {
    declare src_env_file value

    if [[ -v ENV_FILE ]]; then
        src_env_file="${ENV_FILE}"
    else
        src_env_file="${PREFIX:-${DEFAULT_PREFIX}}/etc/prozzie/.env"
    fi

    zz_variables_env_update_array "$src_env_file" "/dev/null"

    if [[ $1 ]]; then
        value="${module_envs[$1]}"
        IFS='|' read -r value _ <<< "${value}" # Using '_' as ignore symbol
        printf '%s: %s' "$1" "$value"
    else
        zz_describe_variables
    fi
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

# Print value of variable.
# Arguments:
#  1 - File from get variables
#  2 - Key to filter
# Environment:
#  -
#
# Out:
#  -
#
# Exit status:
#  Always 0
zz_get_var() {
        grep "${2}" "${1}"|sed 's/^'"${2}"'=//'
}

# Print value of all variables.
# Arguments:
#  1 - File from get variables
#
# Environment:
#  module_envs - Array of variables
#
# Out:
#  -
#
# Exit status:
#  Always 0
zz_get_vars () {
        declare -A env_content

        while IFS='=' read -r key val || [[ -n "$key" ]]; do
                env_content[$key]=$val
        done < "$1"

        for key in "${!module_envs[@]}"; do
                declare value=${env_content[$key]}
                if [[ -n  $value ]]; then
                        printf "%s=%s\n" "$key" "$value"
                fi
        done
}

# Set variable in env file
# Arguments:
#  1 - File from get variables
#  2 - Variable to set
#  3 - Value to set
# Environment:
#  -
#
# Out:
#  -
#
# Exit status:
#  Always 0
zz_set_var () {
    if [[ ! -z "$3" ]]; then
        if [[ "${module_envs[$2]+1}" == 1 ]]; then
            declare value="$3"

            if func_exists "$2_sanitize"; then
                value="$($2_sanitize "${3}")"
            fi

            printf -v new_value "%s=%s" "$2" "$value"

            sed -i '/'"$2"'.*/c\'"$new_value" "$1"
        else
            printf "Variable '%s' not recognized! No changes made to %s\n" "$2" "$1" >&2
	    return 1
        fi
	return 0
    fi
    printf "Variable '%s' can't be empty" "$2" >&2
    return 1
}

# Search for modules in a specific directory and offers them to the user to
# setup them
# Arguments:
#  1 - Directory to search modules from
#  2 - Current temp env file
#  3 - (Optional) list of modules to configure
wizard () {
    declare -r PS3='Do you want to configure modules? (Enter for quit): '
    declare -a modules config_modules
    declare reply
    read -r -a config_modules <<< "$3"

    for module in "${PROZZIE_CLI_CONFIG}"/*.bash; do
        if [[ "$module" == *base.bash ]]; then
            continue
        fi

        # Parameter expansion deletes '../cli/config/' and '.bash'
        modules[${#modules[@]}]="${module:36:-5}"
    done

    while :; do
        if [[ -z ${3+x} ]]; then
            reply=$(zz_select "${modules[@]}")
        elif [[ ${#config_modules[@]} > 0 ]]; then
            reply=${config_modules[-1]}
        else
            reply=''
        fi

        if [[ -z ${reply} ]]; then
            break
        fi

        log info "Configuring ${reply} module\n"

        set +m  # Send SIGINT only to child
        "${PREFIX}"/bin/prozzie config -s ${reply}
        set -m
    done
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

  declare mod_tmp_env
  tmp_fd mod_tmp_env
  trap print_not_modified_warning EXIT

  # Check if the user previously provided the variables. In that case,
  # offer user to mantain previous value.
  zz_variables_env_update_array "$src_env_file" "/dev/fd/${mod_tmp_env}"
  zz_variables_ask "/dev/fd/${mod_tmp_env}"

  # Hurray! app installation end!
  cp -- "/dev/fd/${mod_tmp_env}" "$src_env_file"
  exec {mod_tmp_env}<&-
  trap '' EXIT

  # Reload prozzie
  if [[ $reload_prozzie == y ]]; then
    "${src_env_file%etc/prozzie/.env}/bin/prozzie" up -d
  fi

  unset -v src_env_file
}
