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
    printf -v "$1" '%s' "$(
        # Command substitution avoids overriding complete un-binding. Another
        # way, exiting with Ctrol-C would cause binding ruined.
        bind -u 'complete' 2>/dev/null
        zz_read_path "$1" "$2" "$3" >/dev/tty
        printf '%s' "${!1}"
    )"
}

# ZZ variables treatment. Checks if an environment variable is defined, and ask
# user for value if not. It will check with a dry-run of config module set.
# After that, Save the variable in the environment one.
# Arguments:
#  [--no-check-valid] Do not check if the value is valid
#  $1 The connector name
#  $2 The variable name.
#  $3 Default value if empty text introduced ("" for error raising)
#  $4 Question text
# Environment:
#  module_envs - Associated array to update.
#
# Out:
#  User Interface
#
# Exit status:
#  Always 0
zz_variable () {
  declare check_for_valid=y

  if [[ $1 == --no-check-valid ]]; then
    check_for_valid=n
    shift
  fi

  declare -r module="$1"
  declare default="$3"
  shift

  if [[ -v $1 ]]; then
    declare -r env_provided=y
  else
    declare -r env_provided=n
  fi

  if [[ "$1" == PREFIX || "$1" == *_PATH || "$1" == *_FILE ]]; then
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

    if [[ -z "${!1}" ]]; then
      if [[ "$(zz_connector_var_meta_get "$1" unset_blank n)" == n ]]; then
        log fail "Empty $1 not allowed"$'\n'
        continue
      else
        # Variable accepts blank: no need to call sanitize, since it must do
        # nothing because of the --dry-run
        break
      fi
    fi

    # Check if the value is valid
    if [[ $check_for_valid == y ]] && \
                      ! "${PREFIX}/bin/prozzie" config set --no-reload-prozzie \
                                           "$module" --dry-run "$1=${!1}" > /dev/null; then
      if [[ $env_provided == y ]]; then
        # Tried to force and it fails
        exit 1
      fi

      # Continue the loop
      unset -v "$1"
    fi

    if [[ $env_provided == y ]]; then
        break;
    fi
  done
}

# Update zz variables array default values using a docker-compose .env file. If
# variable it's not contained in module_envs, copy it to .env file
# Arguments:
#  1 - File to read previous values
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
    if ! exists_key_in_module_envs "$var_key"; then
      continue
    fi

    # Update zz variable
    prompt="${module_envs[$var_key]#*|}"
    module_envs[$var_key]=$(printf "%s|%s" "$var_val" "$prompt").
  done < "$1"
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

## Check and set a list of key-value pairs separated by delimiter
## @param --dry-run Do not make any actual change
## @param 1         File from get variables
## @param 2         List of key-value pairs separated by delimiter
##
## @note Use module_envs global variable: user provided key must exists in
## array keys.
##
## @note It print backs the ACTUAL variables that changed, and its new value, or
## error via stderr.
##
## @return True if can change variable, false otherwise.
zz_set_vars () {
    declare -a vars dot_env_vars

    declare dry_run=n pair key val
    if [[ "$1" == '--dry-run' ]]; then
        declare -r dry_run=y
        shift
    fi

    declare -a env_files=("$1")
    shift

    for pair in "$@"; do
        key="${pair%%=*}"
        if [[ $pair != *=* || \
                ($(zz_connector_var_meta_get "$1" unset_blank n) == y && \
                    $pair != *=) ]]; then
            printf "The argument '%s' isn't a valid key=value pair " "$pair" >&2
            printf "and won't be applied\\n" >&2
            return 1
        fi

        val="${pair#*=}"

        if ! exists_key_in_module_envs "${key}"; then
            printf "Variable '%s' not recognized! No changes made to %s\\n" \
                                                 "${key}" "${env_file}" >&2
            return 1
        fi

        if func_exists "${key}_sanitize" && \
                    ! val="$("${key}_sanitize" --dry-run "${val}")"; then
            # Can't sanitize value from command line. Error message must tell
            # the error.
            return 1
        fi

        if [[ $(zz_connector_var_meta_get "$key" is_dot_env n) == y ]] && \
                                ! array_contains "${PREFIX}/etc/prozzie/.env" \
                                "${env_files[@]}"; then
            env_files+=("${PREFIX}/etc/prozzie/.env")
        fi

        if [[ $(zz_connector_var_meta_get "$1" unset_blank n) == n || \
                                                            $pair != *= ]]; then
            if [[ $(zz_connector_var_meta_get "$key" is_dot_env n) == y ]]; then
                dot_env_vars+=("${key}=${val}")
            fi

            vars+=("${key}=${val}")
        fi
    done

    if [[ ${#vars[@]} -gt 0 ]]; then
        printf '%s\n' "${vars[@]}"
    fi

    if [[ $dry_run == y ]]; then
        return 0
    fi

    declare file keys_or_joined applied_warning
    tmp_fd applied_warning

    # Run sanitize functions
    for pair in "$@"; do
        key="${pair%%=*}"
        val="${pair#*=}"

        if func_exists "${key}_sanitize" && \
                                 ! "${key}_sanitize" "${val}" > /dev/null; then
            # Can't sanitize value from command line. Error message must tell
            # the error.
            printf '%s\n' "$(</dev/fd/"${applied_warning}")" >&2
            return 1
        fi

        printf 'Warning! %s modifications applied!\n' "$key" >> \
            /dev/fd/"${applied_warning}"
    done

    # Replace in files
    for file in "${env_files[@]}"; do
        if [[ $file == *"/.env" ]]; then
            # Compose variable
            set -- "${dot_env_vars[@]}"
        else
            # Module variables
            set -- "${vars[@]}"
        fi

        keys_or_joined=$(str_join '\|' "${@/=*/=}")

        {
            # Print only not modified values, if file exists and we can read it
            grep -v "^\\(${keys_or_joined}\\)" "$file" 2>/dev/null

            # Print modified variables
            if [[ $# -gt 0 ]]; then
                printf '%s\n' "$@"
            fi
        } | zz_sponge "$file"
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
wizard () {
    declare -r PS3='Do you want to configure modules? (Enter for quit): '
    declare -r search_prefix='*/cli/config/'
    declare -r suffix='.bash'

    declare -a modules
    declare reply

    for module in "${PROZZIE_CLI_CONFIG}"/*.bash; do
        if [[ "$module" == *base.bash ]]; then
            continue
        fi

        # Parameter expansion deletes '../cli/config/' and '.bash'
        module="${module#$search_prefix}"
        modules[${#modules[@]}]="${module%$suffix}"
    done

    while :; do
        reply=$(zz_select "${modules[@]}")

        if [[ -z ${reply} ]]; then
            break
        fi

        set +m  # Send SIGINT only to child
        "${PREFIX}"/bin/prozzie config setup "${reply}"
        set -m
    done
}

# Set up connector in prozzie, asking the user the connector variables and
# applying them in the provided env file.
# Arguments:
#  1 - The connector name
#
# Environment:
#  module_envs - The variables to ask for, in form:
#    ([global_var]="default|description").
#
# Out:
#  User interface
#
# Note
#  It will call set with --no-reload-prozzie always, so the caller function
#  needs to reload it.
#
# Exit status:
#  Always 0
connector_setup () {
  declare var_key var_default var_prompt var_help
  declare -a new_connector_vars

  declare -r connector="$1"
  declare src_env_file
  src_env_file="$(connector_env_file "$connector")"
  declare -r src_env_file
  shift

  # shellcheck disable=SC2034
  declare zz_trap_stack
  zz_trap_push zz_trap_stack print_not_modified_warning EXIT

  # Check if the user previously provided the variables. In that case,
  # offer user to mantain previous value.
  if [[ -f "$src_env_file" ]]; then
    zz_variables_env_update_array "$src_env_file"
  else
    touch "$src_env_file"
  fi

  for var_key in "${!module_envs[@]}"; do
    IFS='|' read -r var_default var_prompt var_help < \
                                <(squash_spaces <<<"${module_envs[$var_key]}")

    if [[ ! -v "$var_key" && $var_help ]]; then
        printf "%s\\n" "$var_help"
    fi
    zz_variable "$connector" "$var_key" "$var_default" "$var_prompt"

    new_connector_vars+=("${var_key}=${!var_key}")
  done

  "${PREFIX}/bin/prozzie" config set --no-reload-prozzie "$connector" \
                                                      "${new_connector_vars[@]}"

  # Hurray! app installation end!
  zz_trap_pop zz_trap_stack EXIT
}

## @brief INTERNAL name used for connector environment metadata.
## @param  1 Connector environment name
## @param  2 Connector metadata key
##
## @note   Output: Internal variable name
## @return Always true
zz_connector_var_meta_var_name () {
    printf 'pzz__%s__%s' "$1" "$2"
}

## @brief Set metadata for a given connector environment variable
## @param  1 Connector environment name
## @param  2 Connector metadata key
## @param  3 Connector metadata value
##
## @return Always true
zz_connector_var_meta_set () {
    declare meta_name
    meta_name="$(zz_connector_var_meta_var_name "$1" "$2")"

    declare -g "$meta_name"
    printf -v "$meta_name" '%s' "$3"
}

## @brief Checks if metadata exists for a given connector environment variable
## @param  1 Connector environment name
## @param  2 Connector metadata key
##
## @return True if metadata exists, false otherwise
zz_connector_var_meta_exists () {
    declare meta_name
    meta_name="$(zz_connector_var_meta_var_name "$1" "$2")"
    [[ -v "$meta_name" && -n "${!meta_name}" ]]
}

## @brief Get metadata for a given connector environment variable
## @param  1 Connector environment name
## @param  2 Connector metadata key
## @param  3 Connector metadata default if it does not exists
##
## @return False if it does not exists and it does not have a default
zz_connector_var_meta_get () {
    declare meta_name
    meta_name="$(zz_connector_var_meta_var_name "$1" "$2")"

    if [[ ! -v "$meta_name" ]]; then
        if [[ ! -v 3 ]]; then
            return 1
        fi

        printf '%s' "$3"
        return
    fi

    printf '%s' "${!meta_name}"
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

    # zz_trap_push/pop use this variable
    # shellcheck disable=SC2034
    declare zz_trap_stack
    # If can't write, return properly. It may be grep -q or similar.
    zz_trap_push zz_trap_stack 'return 0' SIGPIPE

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

    zz_trap_pop zz_trap_stack SIGPIPE
}

##
## @brief      Allows "install" connectors of kafka-connect.
##             Basically add the *.jar file to kafka-connect docker volume and
##             copy or generate the config bash file to ${PREFIX}/share/prozzie/cli/config
##
## @param  [--dry-run] Do not make any actual change, just validate input
## @param  [--kafka-connector] Mandatory, jar file to add to kafka-connect docker volume
## @param  [--config-file] Mandatory, configuration bash file
##
## @return     0 If everything goes well or 1 If an error occurred
##
zz_install_connector () {

    usage() {
		cat <<-EOF
			prozzie config install [--help] [--dry-run] --kafka-connector <path-to-jar> --config-file <path-to-config-bash-file>
			--dry-run                       Only validate the configuration, do not modify anything
			--kafka-connector               Path to kafka-connect connector jar file
			--config-file[.json|yaml]       Path to kafka-connect connector configuration bash file or json/yaml schema
		EOF
    }

    declare args=("$@" --)
    set -- "${args[@]}"
    declare dry_run_arg
    declare connector_file_path
    declare config_file_cmd_base="--config-file."
    declare config_file_path
    declare config_filename
    declare file_type
    declare is_kafka_connector=y

    while true; do
        case $1 in
        --dry-run)
            dry_run_arg=--dry-run
            shift
            ;;
        --kafka-connector|--compose-file)
            if [[ ! -f "$2" ]]; then
                printf "The file '%s' doesn't exist\\n" "$2"
                exit 1
            fi

            if [[ $1 != --kafka-connector ]]; then
                is_kafka_connector=n
            fi
            connector_file_path="$2"
            shift 2
            ;;
        --config-file*)
            if [[ ! -f "$2" ]]; then
                printf "The file '%s' doesn't exist\\n" "$2"
                exit 1
            fi
            config_file_path="$2"
            config_filename="${config_file_path##*/}"
            file_type=${1#"$config_file_cmd_base"}
            shift 2
            ;;
        --)
            shift
            break
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
        esac
    done

    if [[ -z $connector_file_path ]]; then
        printf -- "--kafka-connector <path-to-jar> or --compose-file <path-to-file> is required\\n"
        exit 1
    fi

    if [[ -z $config_file_path ]]; then
        printf -- "--config-file[.json] <path-to-bash-config-file> is required\\n"
        exit 1
    fi

    declare -r kafka_connect_jars_volume="prozzie_kafka_connect_jars"
    declare module_env_vars
    declare module_hidden_env_vars
    declare config_filename="${config_file_path##*/}"
    config_filename=${config_filename%.*}
    declare input_json_file_path="$config_file_path"
    declare bash_file=y

    case $file_type in
        json|yaml)

            if [[ "$file_type" == yaml ]]; then
                tmp_fd input_json_file_path
                input_json_file_path=/dev/fd/"$input_json_file_path"
                zz_toolbox_exec -i -- y2j < "$config_file_path" > "$input_json_file_path"
            fi

            if ! zz_toolbox_exec -i -- jq -e . < "$input_json_file_path" > /dev/null 2>&1; then
                printf "Failed to parse %s, or got false/null\\n" "$file_type" >&2
                exit 1
            fi

            bash_file=n
        ;;
        *)
            if [[ -z $dry_run_arg ]]; then
                if ! cp "$config_file_path" "${PROZZIE_CLI_CONFIG}"; then
                    return 1;
                fi
            fi

            printf "Added %s to %s\\n" "$config_file_path" "${PROZZIE_CLI_CONFIG}"
        ;;
    esac

    if [[ $bash_file == n ]];then
        declare -r jq_query_base="if has(\"configs\") then .configs[] else error(\"'configs' key is not defined!\") end
        | if has(\"var_name\") then . else error(\"'var_name' key is not defined!\") end
        | if has(\"hidden\") then . else . + {hidden: false} end
        | select(.hidden==#IS_HIDDEN#)
        | \"[\\(.var_name)]='\\(if .default_value != null then .default_value else \"\" end)|\\(if .description != null then .description else \"\" end)'\""

        if ! module_env_vars=$(zz_toolbox_exec -i -- jq -r "${jq_query_base/\#IS_HIDDEN\#/false}" < "$input_json_file_path") \
            || ! module_hidden_env_vars=$(zz_toolbox_exec -i -- jq -r "${jq_query_base/\#IS_HIDDEN\#/true}" < "$input_json_file_path"); then
            printf "Error to parse vars in file %s\\n" "$input_json_file_path" >&2
            exit 1
        fi

        generate_config_bash_file \
            ${dry_run_arg:-} "$is_kafka_connector" "$config_filename" "$module_env_vars" "$module_hidden_env_vars"
    fi

    # zz_trap_push/pop use this variable
    # shellcheck disable=SC2034
    declare trap_copy_to_volume_or_directory_stack
    zz_trap_push trap_copy_to_volume_or_directory_stack "rm ${PROZZIE_CLI_CONFIG}/$config_filename.bash" EXIT

    if [[ "$is_kafka_connector" == y ]] && zz_docker_copy_file_to_volume \
            ${dry_run_arg:-} f "$connector_file_path" "$kafka_connect_jars_volume"; then

        if [[ -z $dry_run_arg ]]; then
            printf "Added kafka connector %s\\n" "$connector_file_path"

            "${PREFIX}"/bin/prozzie compose rm -s -f kafka-connect 2>&1 | \
            grep -v 'No such service: kafka-connect' >&2

            "${PREFIX}"/bin/prozzie up -d
        else
            printf "kafka connector %s would be added\\n" "$connector_file_path"
        fi
    else
        if [[ -z $dry_run_arg ]]; then
            if ! "${PREFIX}"/bin/prozzie compose --file "$connector_file_path" config > /dev/null; then
                printf "The file '%s' isn't a valid compose file\\n" "$connector_file_path" >&2
                return 1
            fi

            if ! cp "$connector_file_path" "${PREFIX}/share/prozzie/compose"; then
                return 1
            fi
            printf "Added compose file %s to %s\\n" "${PREFIX}/share/prozzie/compose" "$connector_file_path"
        else
            printf "Docker-compose file %s would be added\\n" "$connector_file_path"
        fi
    fi

    zz_trap_pop trap_copy_to_volume_or_directory_stack EXIT
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

##
## @brief      Generates a new config bash file in ${PREFIX}/share/prozzie/cli/config
##
## @param  [--dry-run] Do not create any config bash file, just show the output
## @param  1 - If value is 'y' the genetared file is for kafka-connect else is for docker-compose
## @param  2 - Filename to create the config bash file without extension
## @param  3 - Array that contains the module envs to add to config bash file
## @param  4 - Array that contains the module hidden envs to add to config bash file
##
## Out:
##  User interface
##
## @return     Always 0
##
generate_config_bash_file() {
    printf "Generating config bash file. Please wait..."
    declare -r SHEBANG_HEADER="#!/usr/bin/env bash"
    declare -r FILE_GENERATION_WARNING="# WARNING: This file is automatically generated. Edit under your own risk."
    declare SOURCE_FILE=". \"\${BASH_SOURCE%/*/*}/include/config_kcli.bash\""
    declare -r MODULE_ENVS_ARRAY_TEMPLATE="declare -A module_envs=(#CONTENT#)"
    declare -r MODULE_HIDDEN_ENVS_ARRAY_TEMPLATE="declare -A module_hidden_envs=(#CONTENT#)"
    declare dry_run=n
    declare output1 output2

    if [[ $1 == '--dry-run' ]]; then
        dry_run=y
        shift
    fi

    declare -r is_kafka_connector="$1"
    shift

    if [[ "$is_kafka_connector" == n ]]; then
        SOURCE_FILE=". \"\${BASH_SOURCE%/*/*}/include/config_compose.bash\""
    fi

    declare -r config_filename="$1"
    printf -v module_envs_content "\\n%s" "$2"
    printf -v module_hidden_envs_content "\\n%s" "$3"

    printf -v output1 "%s\\n\\n" "$SHEBANG_HEADER" "$FILE_GENERATION_WARNING" "$SOURCE_FILE" \
                      "${MODULE_ENVS_ARRAY_TEMPLATE/\#CONTENT\#/$module_envs_content}"

    printf -v output2 "%s\\n" "${MODULE_HIDDEN_ENVS_ARRAY_TEMPLATE/\#CONTENT\#/$module_hidden_envs_content}"

    declare output="$output1$output2"
    printf "Done!\\n"
    printf "Generated file: %s\\n" "${PROZZIE_CLI_CONFIG}/$config_filename".bash

    if [[ $dry_run == y ]]; then
        printf "%s" "$output"
    else
        printf "%s" "$output" > "${PROZZIE_CLI_CONFIG}/$config_filename".bash
    fi
}
