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

            declare -r module_config_file="$PROZZIE_CLI_CONFIG/$module.bash"
            # Check that module's config file exists
            if [[ ! -f "$module_config_file" ]]; then
                printf "Unknown module: '%s'\\n" "$module" >&2
                printf "Please use 'prozzie config describe-all' to see a complete list of modules and their variables\\n" >&2
                exit 1
            fi

            . "$module_config_file"
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
                    showVarsDescription
                    return
                ;;
                setup)
                    printf 'Setup %s module:\n' "$module"
                    zz_connector_setup "$module" "$@"
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
                . "$config_module"

                config_module=${config_module#$prefix}
                printf 'Module %s: \n' "${config_module%$suffix}"

                showVarsDescription
            done
            exit 0
        ;;
        enable|disable)
            zz_enable_disable_modules "$action" "$@"
            exit 0
        ;;
        list-enabled)
            zz_list_enabled_modules
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
