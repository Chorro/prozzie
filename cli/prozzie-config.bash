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
declare -r PROZZIE_ENVS="${PREFIX:-${DEFAULT_PREFIX}}/etc/prozzie/envs"

# .env file path
declare base_env_file="${PREFIX:-${DEFAULT_PREFIX}}/etc/prozzie/.env"

printShortHelp() {
    printf "Handle prozzie configuration\n"
}

printHelp() {
    printShortHelp
    printf "\tusage: prozzie config [<options>] [<module>] [<key>] [<value>]\n"
    printf "\t\tOptions:\n"
    printf "\t\t%-40s%s\n" "-w, --wizard" "Start modules wizard"
    printf "\t\t%-40s%s\n" "-d, --describe <module>" "Describe module vars"
    printf "\t\t%-40s%s\n" "-s, --setup <module>" "Configure module with setup assistant"
    printf "\t\t%-40s%s\n" "--describe-all" "Describe all modules vars"
    printf "\t\t%-40s%s\n" "--enable <module>" "Enable module"
    printf "\t\t%-40s%s\n" "--disable <module>" "Disable module"
    printf "\t\t%-40s%s\n" "-h, --help" "Show this help"
}

describeModule () {
    if [[ -f "$PROZZIE_CLI_CONFIG/$1.bash" ]]; then
        . "$PROZZIE_CLI_CONFIG/$1.bash"
        showVarsDescription
        return 0
    fi
    printf "Module '%s' not found!\n" "$2" >&2
    return 1
}

# Show help if option is not present
if [[ $# -eq 0 ]]; then
    printHelp
fi

if [[ $1 ]]; then
    case $1 in
        --shorthelp)
            printShortHelp
            exit 0
        ;;
        -h|--help)
            printHelp
            exit 0
        ;;
        -w|--wizard)
            wizard "$src_env_file"
            exit 0
        ;;
        -d|--describe)
            if [[ $2 ]]; then
                printf "Module ${2}: \n"
                describeModule "$2" || exit 1
            else
                printHelp
                exit 1
            fi
        ;;
        --describe-all)
            declare -r prefix="*/cli/config/"
            declare -r suffix=".bash"

            for config_module in "$PROZZIE_CLI_CONFIG"/*.bash; do
                . "$config_module"

                config_module=${config_module#$prefix}
                printf "Module ${config_module%$suffix}: \n"

                showVarsDescription
            done
            exit 0
        ;;
      -s|--setup)
            if [[ -f "$PROZZIE_CLI_CONFIG/$2.bash" ]]; then
                module="$PROZZIE_CLI_CONFIG/$2.bash"
                . "$module"
                if [[ $2 == mqtt || $2 == syslog ]]; then
                    . "${BASH_SOURCE%/*}/include/kcli_base.bash"
                    tmp_fd properties
                    kcli_setup "/dev/fd/${properties}" "$2"
                    exec {properties}<&-
                else
                    ENV_FILE="$PROZZIE_ENVS/$2.env"
                    printf "Setup %s module:\n" "$2"
                    shift 1
                    app_setup "$@"
                fi
                exit 0
            fi
            printHelp
            exit 1
        ;;
        --enable|--disable)
            zz_link_unlink_module $@
            exit 0
        ;;
        *)
            declare -r option="$PROZZIE_CLI_CONFIG/$1.bash"

            if [[ ! -f "$option" ]]; then
                printf "Unknow module: %s\nPlease use 'prozzie config --describe-all' to see a complete list of modules and their variables\n" "$1" >&2
                exit 1
            fi

            . "$option"
            module=$1
            shift 1
            declare env_file="$PROZZIE_ENVS/$module.env"
            # If module is referred to base module then set $env_file to $base_env_file
            if [[ "$module" =~ ^base$ ]]; then
                env_file="$base_env_file"
            fi
            case $# in
                0)
                    if [[ "$module" =~ ^(mqtt|syslog)$ ]]; then
                        "${PREFIX}"/bin/prozzie kcli get "$module"
                        exit 0
                    fi
                    zz_get_vars "$env_file"
                    exit 0
                ;;
                1)
                    if [[ "$module" =~ ^(mqtt|syslog)$ ]]; then
                        "${PREFIX}"/bin/prozzie kcli get "$module"|grep -P "^${1}=.*$"|sed 's/'"${1}"'=//'
                        exit 0
                    fi
                    zz_get_var "$env_file" "$@"
                    exit 0
                ;;
                2)
                    if [[ "$module" =~ ^(mqtt|syslog)$ ]]; then
                        printf "Please use next commands in order to configure ${module}:\n" >&2
                        printf "prozzie kcli rm <connector>\n" >&2
                        printf "prozzie config -s ${module}\n" >&2
                        exit 1
                    fi
                    zz_set_var "$env_file" "$@" || exit 1
                ;;
            esac
        ;;
    esac
fi
