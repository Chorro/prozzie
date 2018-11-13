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

# Includes
. "${BASH_SOURCE%/*}/include/common.bash"
. "${BASH_SOURCE%/*}/include/config.bash"
. "${BASH_SOURCE%/*}/include/cli.bash"

# Declare prozzie cli config directory path
declare -r PROZZIE_CLI_CONFIG="${BASH_SOURCE%/*}/config"

printShortHelp() {
    printf 'Handle prozzie configuration\n'
}

printUsage() {
    declare -A commands_and_options_descriptions=(
        ['get <module>']='Get the configuration of the specified module'
        ['get <module> <key>...']='Get the configuration of the specified key in specified module'
        ['set <module> <key>=<value>...']='Set the configuration of the list of pairs key-value for a specified module'
        ['wizard']='Start modules wizard'
        ['describe <module>']='Describe module vars'
        ['setup <module>']='Configure module with setup assistant'
        ['describe-all']='Describe all modules vars'
        ['enable <modules-list>']='Enable modules'
        ['disable <modules-list>']='Disable modules'
        ['list-enabled']='List all enabled modules'
        ['-h, --help']='Show this help'
    )

    declare -a actions_order=(
        'get <module>'
        'get <module> <key>...'
        'set <module> <key>=<value>...'
        'describe <module>'
        'enable <modules-list>'
        'disable <modules-list>'
        'setup <module>'
        'wizard'
        'describe-all'
        'list-enabled'
    )

    declare -a options_order=(
        '-h, --help'
    )

    printf 'usage: prozzie config <action> [args]\n'
    printf '   or: prozzie config <option>\n'
    printf '\nAvailable actions are:\n'

    for comm in "${actions_order[@]}"
    do
        apply_help_command_format "$comm" "${commands_and_options_descriptions[$comm]}"
    done

    printf '\nAvailable options are:\n'

    for opt in "${options_order[@]}"
    do
        apply_help_command_format "$opt" "${commands_and_options_descriptions[$opt]}"
    done
}

##
## @brief      Obtain a module config file. If it does not exist, a message will
##             be printed offering help to the user.
##
## @param      1 module name
##
## @return     True if the module config file exists, false otherwise.
##
module_config_file () {
    declare -r module="$1"

    declare -r config_file="$PROZZIE_CLI_CONFIG/$module.bash"

    # Check that module's config file exists
    if [[ ! -f "$config_file" ]]; then
        printf "Unknown module: '%s'\\n" "$module" >&2
        printf "Please use 'prozzie config describe-all' to see a complete list of modules and their variables\\n" >&2
        return 1
    fi

    printf '%s' "$config_file"
}

##
## @brief      Print connector usage hint to the user, if the connector provides
##             it
##
## @return     Always 0
##
config_connector_print_hint () {
    declare -r module="$1"

    if ! func_exists zz_connector_print_send_message_hint; then
        return 0
    fi

    # Load needed variables
    declare env_var env_val

    # PREFIX must be declared from prozzie cli
    # shellcheck disable=SC2153
    while IFS='=' read -r env_var env_val; do
        printf -v "$env_var" '%s' "$env_val"
    done < "${PREFIX}/etc/prozzie/.env"

    # module_envs needs to be imported from ${config_file}
    # shellcheck disable=SC2154
    for env_var in "${!module_envs[@]}"; do
        # Escape variables dots
        escaped_env_var="${env_var//./__}"
        env_val_no_description="${module_envs[$env_var]%|*}"
        printf -v "$escaped_env_var" '%s' "${env_val_no_description}"
    done

    zz_connector_print_send_message_hint "$module"
}

main() {
    declare action="$1"

    # Show help if options are not present
    if [[ $# -eq 0 ]]; then
        printUsage
        exit 0
    fi

    shift

    case $action in
        get|set|describe|setup)
            # Check that parameters has been passed
            if [[ $# -eq 0 ]]; then
                printUsage
                case $action in
                    describe|setup)
                        return 1
                        ;;
                    *)
                        return 0
                        ;;
                esac
            fi

            # Get module
            declare -r module="$1"
            shift

            declare config_file
            config_file=$(module_config_file "$module") || return
            declare -r config_file

            . "$config_file"
            case $action in
                set)
                    zz_connector_set_variables "$module" "$@"
                ;;
                get)
                    zz_connector_get_variables "$module" "$@"
                    return
                ;;
                describe)
                    printf 'Module %s: \n' "${module}"
                    zz_connector_show_vars_description
                    return
                ;;
                setup)
                    printf 'Setup %s module:\n' "$module"
                    if zz_connector_setup "$module" "$@"; then
                        config_connector_print_hint "$module"
                    else
                        return 1
                    fi

                    return
                ;;
            esac
        ;;
        wizard)
            wizard
            return
        ;;
        describe-all)
            declare -r prefix="*/cli/config/"
            declare -r suffix=".bash"

            for config_module in "$PROZZIE_CLI_CONFIG"/*.bash; do
                (. "$config_module"

                config_module=${config_module#$prefix}
                printf 'Module %s: \n' "${config_module%$suffix}"

                zz_connector_show_vars_description)
            done
            exit 0
        ;;
        enable|disable)
            declare module config_file action_callback return_code=0

            case $action in
                enable)
                    action_callback=zz_connector_enable
                    ;;
                disable)
                    action_callback=zz_connector_disable
                    ;;
            esac
            for module in "$@"; do
                (config_file=$(module_config_file "$module") && {
                    . "$config_file"
                    if ! $action_callback "$module"; then
                        return 1
                    fi

                    if [[ $action == enable ]]; then
                        config_connector_print_hint "$module"
                    fi
                }) || return_code=1
            done

            # PREFIX must be defined
            # shellcheck disable=SC2153
            "${PREFIX}/bin/prozzie" up --remove-orphans -d || return_code=1
            exit $return_code
        ;;
        list-enabled)
            zz_list_enabled_modules "$@"
            exit 0
        ;;
        --shorthelp)
            printShortHelp
            exit 0
        ;;
        -h|--help)
            printShortHelp
            printUsage
            exit 0
        ;;
        *)
            printf "error: unknown action '%s'\\n" "$action"
            printUsage
            exit 1
        ;;
    esac
}

main "$@"
