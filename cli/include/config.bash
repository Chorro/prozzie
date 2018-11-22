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
# user for value if not. It will sanitize the variable in both cases.
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
  declare new_value default="$2"
  declare -r env_file="$4"

  if [[ -v $1 ]]; then
    declare -r env_provided=y
  else
    declare -r env_provided=n
  fi

  if [[ "$1" == PREFIX || "$1" == *_PATH ]]; then
    declare -r read_callback=zz_read_path
  else
    declare -r read_callback=zz_read
  fi

  if func_exists "$1_hint" && [[ -z "$default" ]]; then
    default=$("$1_hint")
  fi
  declare -r default

  while [[ -z "${!1}" || $env_provided == y ]]; do
    if [[ $env_provided == n ]]; then
      "$read_callback" "$1" "$3" "$default"
    fi

    if [[ -z "${!1}" && -z "$default" ]]; then
      log fail "[${!1}][$default] Empty $1 not allowed"$'\n'
      continue
    fi

    if func_exists "$1_sanitize"; then
      if ! new_value=$("$1_sanitize" "${!1}"); then
        if [[ $env_provided == y ]]; then
          exit 1
        fi
        new_value=''
      fi

      printf -v "$1" '%s' "$new_value"
    fi

    if [[ $env_provided == y ]]; then
      break
    fi
  done

  if [[ $1 != PREFIX ]]; then
    printf '%s=%s\n' "$1" "${!1}" >> "$env_file"
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
  declare prompt var_key var_val
  while IFS='=' read -r var_key var_val || [[ -n "$var_key" ]]; do
    if exists_key_in_module_envs "$var_key"; then
      # Update zz variable
      prompt="${module_envs[$var_key]#*|}"
      module_envs[$var_key]=$(printf "%s|%s" "$var_val" "$prompt")
    else
      # Copy to output .env file
      printf '%s=%s\n' "$var_key" "$var_val" >> "$2"
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
    local var_default var_prompt var_help

    IFS='|' read -r var_default var_prompt var_help < \
                                        <(squash_spaces <<<"${module_envs[$2]}")

    if [[ ! -z $var_help ]]; then
        printf "%s\\n" "$var_help"
    fi

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
        log warn "No changes made to $src_env_file"$'\n'
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
#  @ - What variables to get. It will get all module variables if empty.
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
        declare -r env_file="$1"
        shift

        # If keys list is empty then show all variables
        if [[ $# -eq 0 ]]; then
            declare -A env_content
            # Read from env_file
            while IFS='=' read -r key val || [[ -n "$key" ]]; do
                env_content[$key]=$val
            done < "$env_file"
            # Show variables
            for key in "${!module_envs[@]}"; do
                declare value=${env_content[$key]}
                if [[ -n  $value ]]; then
                        printf '%s=%s\n' "$key" "$value"
                fi
            done
        fi

        for key in "$@"; do
            zz_get_var "$env_file" "$key" || \
                                           printf "Key '%s' is not valid" "$key"
        done
}

# Set variable in env file
# Arguments:
#  [[ --dry-run ]] Do not change anything in env file or in actual variables
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
#  0 - Variable is set without error
#  1 - An error has ocurred while set a variable (variable not found or mispelled)
zz_set_var () {
    declare dry_run=n key_value
    if [[ $1 == --dry-run ]]; then
        dry_run=y
        shift
    fi

    if exists_key_in_module_envs "$2"; then
        declare value="$3"

        if func_exists "$2_sanitize" && ! value="$("$2_sanitize" "${3}")"; then
            # Can't sanitize value from command line
            return 1
        fi

        if [[ $dry_run == n ]]; then
            printf -v key_value "%s=%s" "$2" "$value"
            sed -i "/$2.*/c$key_value" "$1"
        fi
    else
        printf "Variable '%s' not recognized! No changes made to %s\\n" "$2" "$1" >&2
        return 1
    fi
}

# Check and set a list of key-value pairs separated by delimiter
# Arguments:
#  [[--dry-run]] - Do not make any actual change
#  1 - File from get variables
#  2 - List of key-value pairs separated by delimiter
# Environment:
#  -
#
# Out:
#  -
#
# Exit status:
#  Always 0
zz_set_vars () {
    declare key val

    declare dry_run_arg
    if [[ "$1" == '--dry-run' ]]; then
        dry_run_arg=--dry-run
        shift
    fi

    declare -r env_file="$1"
    shift

    if [[ -z $dry_run_arg ]]; then
        # Check that all parameters are OK before do any change
        zz_set_vars --dry-run "$env_file" "$@" || return 1
        dry_run_arg=
    fi
    declare -r dry_run_arg

    for pair in "$@"; do
        if [[ $pair != *=* ]]; then
            printf "The argument '%s' isn't a valid key=value pair " "$pair" >&2
            printf "and won't be applied\\n" >&2
            return 1
        else
            key=${pair%%=*}
            val="${pair#*=}"

            zz_set_var $dry_run_arg "$env_file" "$key" "$val" || return 1
        fi
    done
}

# Set variable in env file by default
# Arguments:
#  1 - Module to set by default
# Environment:
#  -
#
# Out:
#  -
#
# Exit status:
# Always true
zz_set_default () {
    declare -a default_config=( '#Default configuration' )

    for var_key in "${!module_envs[@]}"; do
        printf -v new_value '%s=%s' "${var_key}" "${module_envs[$var_key]%|*}"
        default_config+=("$new_value")
    done
    printf '%s\n' "${default_config[@]}" > "$1"
}

# Search for modules in a specific directory and offers them to the user to
# setup them
# Arguments:
#  1 - Directory to search modules from
#  2 - Current temp env file
#  3 - (Optional) list of modules to configure
wizard () {
    declare -r PS3='Do you want to configure modules? (Enter for quit): '
    declare -r search_prefix='*/cli/config/'
    declare -r suffix='.bash'

    declare -a modules config_modules
    declare reply
    read -r -a config_modules <<< "$3"

    for module in "${PROZZIE_CLI_CONFIG}"/*.bash; do
        if [[ "$module" == *base.bash ]]; then
            continue
        fi

        # Parameter expansion deletes '../cli/config/' and '.bash'
        module="${module#$search_prefix}"
        modules[${#modules[@]}]="${module%$suffix}"
    done

    while :; do
        if [[ -z ${3+x} ]]; then
            reply=$(zz_select "${modules[@]}")
        elif [[ ${#config_modules[@]} -gt 0 ]]; then
            reply=${config_modules[-1]}
        else
            reply=''
        fi

        if [[ -z ${reply} ]]; then
            break
        fi

        set +m  # Send SIGINT only to child
        "${PREFIX}"/bin/prozzie config setup ${reply}
        set -m
    done
}

# Set up connector in prozzie, asking the user the connector variables and
# applying them in prozzie.
# Arguments:
#  [--no-reload-prozzie] Don't reload prozzie at the end of `.env` changes
#  1 - env file to modify
#  n - Callback + arguments before send reload to docker compose. Can be empty.
#
# Environment:
#  PREFIX - Where to look for the `.env` file.
#  ENV_FILE - The path of `.env` file to modify. Defaults to
#    ${PREFIX}/etc/prozzie/.env if not declared
#  module_envs - The variables to ask for, in form:
#    ([global_var]="default|description"). See also
#    `zz_variables_env_update_array` and `zz_variables_ask`
#
# Out:
#  User interface
#
# Exit status:
#  Always 0
connector_setup () {
  declare reload_prozzie=y
  if [[ $1 == --no-reload-prozzie ]]; then
    reload_prozzie=n
    shift
  fi

  declare -r src_env_file="$1"
  shift

  touch "$src_env_file"

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

  if [[ $# -gt 1 ]]; then
    "$@"
  fi

  # Reload prozzie
  if [[ $reload_prozzie == y ]]; then
    "${PREFIX}/bin/prozzie" up -d
  fi
}

# List enable modules
# Arguments:
#  [--quiet|-q] Only show modules
# Exit status:
#  Always 0
zz_list_enabled_modules() {
    [[ $# -lt 1 || ($1 != -q && $1 != --quiet) ]] && printf 'Enabled modules:\n'
    declare -r search_prefix='*/compose/'
    declare -r suffix='.yaml'

    declare restore_sigpipe_cmd
    restore_sigpipe_cmd=$(trap -p SIGPIPE)
    if [[ -z "$restore_sigpipe_cmd" ]]; then
        restore_sigpipe_cmd='trap - SIGPIPE'
    fi
    declare -r restore_sigpipe_cmd

    # If can't write, return properly. It may be grep -q or similar.
    trap '$restore_sigpipe_cmd; return 0' SIGPIPE

    # Yaml modules
    for module in "${PREFIX}"/etc/prozzie/compose/*.yaml; do
        if [[ $module =~ /base.yaml$ ]]; then
            continue
        fi
        module=${module#$search_prefix}
        printf '%s\n' "${module%$suffix}"
    done

    # Kafka connect modules
    for module in $("${PREFIX}"/bin/prozzie kcli ps); do
        "${PREFIX}/bin/prozzie" kcli status "$module" | head -n 1 | \
                        grep -q 'RUNNING' && printf '%s\n' "$module"
    done

    $restore_sigpipe_cmd
}

##
## @brief      Prints description of every variable in module_envs and
##             module_hidden_envs environment variables via stdout.
##
## No Arguments
##
## Environment:
##  module_envs - Module's environment as usual
##  module_hidden_envs - Module's hidden environment as usual
##
## Out:
##  User interface
##
## @return     Always 0
##
zz_connector_show_vars_description () {
    declare -r not_pipe='[^\|]'
    declare var_key var_description

    # module_{hidden_}envs is supposed to be present when prozzie calls this
    # function
    # shellcheck disable=2154
    for var_key in "${!module_envs[@]}" "${!module_hidden_envs[@]}"; do
        var_description="${module_envs[$var_key]-${module_hidden_envs[$var_key]}}"
        # Variable description is in between '|'
        # Shellcheck say that we must replace '\' for '\\', but is simply wrong
        # shellcheck disable=1117
        var_description=$(sed \
                          "s%${not_pipe}*|\(${not_pipe}*\).*%\1%" \
                          <<<"$var_description" | squash_spaces)

        printf '\t%-40s%s\n' "${var_key}" "${var_description}"
    done
}
