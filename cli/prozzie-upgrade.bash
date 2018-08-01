#!/usr/bin/env bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

. "${BASH_SOURCE%/*}/include/common.bash"
. "${BASH_SOURCE%/*}/include/cli.bash"

# Get current release
current_release=$(<"${PREFIX}/etc/prozzie/.version")
declare -r current_release

printShortHelp() {
    printf "Check and upgrade Prozzie to latest release\\n"
}

printUsage() {
    declare -A options_descriptions=(
        ["--from-git (-y, --yes, --assumeyes)"]="Upgrade Prozzie from git master branch to get latest changes (This is dangerous!)"
        ["--from-git=<branch|commit> (-y, --yes, --assumeyes)"]="Upgrade Prozzie from git specified branch or commit to get changes (This is dangerous!)"
        ["--prerelease (-y, --yes, --assumeyes)"]="Upgrade Prozzie with latest pre-release"
        ["-y, --yes, --assumeyes"]="Automatic yes to prompts. Assume \"yes\" as answer to all prompts and run non-interactively"
        ["-f, --force"]="Disable checks and force upgrade to latest release"
        ["--check-for-upgrades"]="Check for available Prozzie release"
        ["-h, --help"]="Show this help"
    )

    declare -a options_order=(
        "--from-git (-y, --yes, --assumeyes)"
        "--from-git=<branch|commit> (-y, --yes, --assumeyes)"
        "--prerelease (-y, --yes, --assumeyes)"
        "-y, --yes, --assumeyes"
        "-f, --force"
        "--check-for-upgrades"
        "-h, --help"
    )

    printf "usage: prozzie upgrade <options> [args]\\n"
    printf "\\nAvailable options are:\\n"

    for opt in "${options_order[@]}"
    do
        apply_help_command_format "$opt" "${options_descriptions[$opt]}"
    done
}

# Main
main () {
    # Options to activate
    declare -A options_activation=(
        ["--from-git"]="n"
        ["--prerelease"]="n"
        ["force"]="n"
        ["assumeyes"]="n"
        ["--check-for-upgrades"]="n"
        ["help"]="n"
        ["--shorthelp"]="n"
        ["git-ref"]=""
    )

    # Upgrade by default
    declare upgrade
    upgrade='y'
    # Upgrade to <version> (empty by default)
    declare upgrade_to
    upgrade_to=''

    while [[ "$1" == '-'* ]]; do
        case $1 in
            -h|--help) options_activation["help"]=y
            ;;
            -y|--yes|--assumeyes) options_activation["assumeyes"]=y
            ;;
            -f|--force) options_activation["force"]=y
            ;;
            --from-git=*)
                options_activation["--from-git"]=y
                options_activation["git-ref"]="${1#*=}"
            ;;
            *)
                if [[ ${options_activation["$1"]} ]]; then
                    options_activation["$1"]=y
                else
                    printf "Option '%s' not recognized!\\n" "$1"
                    exit 1
                fi
            ;;
        esac
        shift
    done

    if [[ ${options_activation["--shorthelp"]} == 'y' ]]; then
        printShortHelp
        exit 0
    elif [[ ${options_activation["help"]} == 'y' ]]; then
        printUsage
        exit 0
    elif [[ ${options_activation["--from-git"]} == 'y' ]]; then
        log warn $'You are going to upgrade prozzie from git master branch. This version could be unstable\n'
        upgrade_to="${options_activation["git-ref"]:-master}"
    elif [[ ${options_activation["--prerelease"]} == 'y' ]]; then
        printf "Checking latest prozzie prerelease, please wait...\\n"
        if ! upgrade_to="$(print_github_last_prerelease)"; then
            printf "Error to get information about latest prozzie prerelease\\n" >&2
            exit 1
        fi
        printf "Latest prerelease: %s\\n" "$upgrade_to"
        log warn $'You are going to upgrade prozzie to latest prerelease.\n'
    elif [[ ${options_activation["--check-for-upgrades"]} == 'y' ]]; then
        upgrade='n'
        if ! upgrade_to="$(print_github_last_release)"; then
            printf "Error to get information about latest prozzie release\\n"
            exit 1
        fi
        if [[ ! -z "${current_release}" ]]; then
            printf "Prozzie current version: %-15s\\n" "${current_release}"
        fi
        if [[ ! -z "${upgrade_to}" ]]; then
            printf "Prozzie latest version: %-15s\\n" "${upgrade_to}"
        fi
    else
        if ! upgrade_to="$(print_github_last_release)"; then
            printf "Error to get information about prozzie latest release\\n" >&2
            exit 1
        fi
        if [[ ${options_activation["force"]} == 'n' ]]; then
            # Compare if current_release and upgrade_to are equals
            if [[ "$current_release" == "$upgrade_to" ]]; then
                printf "Your installed Prozzie version is %s, and the latest Prozzie release is %s\\n" "$current_release" "$upgrade_to"
                printf "Your Prozzie is up to date!\\n"
                exit 0
            # Compare if current_release is greater than upgrade_to
            elif test "$(printf "%s\\n" "$current_release" "$upgrade_to" | sort -t. -k 1,1n -k 2,2n -k 3,3n | head -n 1)" != "$1"; then
                printf "Your installed Prozzie version is %s, but the latest release is %s!\\n" "$current_release" "$upgrade_to"
                printf "If you have a prerelease installed or you have modified the .version file, please install a stable Prozzie version\\n"
                exit 1
            else # current_release is lower than upgrade_to
                printf "Prozzie version %s is released!\\n" "$upgrade_to"
                printf "For more details please refer to https://github.com/wizzie-io/prozzie/releases/tag/%s\\n\\n" "$upgrade_to"
            fi
        fi
    fi

    if [[ "$upgrade" == 'y' ]]; then
        if [[ ${options_activation["force"]} == 'y' ]]; then
            log warn $'You are goint to force upgrade to version '"$upgrade_to"$'\n'
        fi
        if [[ ${options_activation["assumeyes"]} == 'y' ]] || read_yn_response "Do you want to continue?"; then
            upgrade_to_new_version "$upgrade_to"
        else
            printf "No changes were made\\n\\n"
        fi
        exit 0
    fi
}

# Print most recent prerelease in github repository
# Arguments:
# Exit status:
#  Always 0
print_github_last_prerelease () {
    # Get latest github prerelease
    declare latest_prerelease
    if ! latest_prerelease=$(docker run -it cfmanteiga/alpine-bash-curl-jq:latest bash -c "curl --silent https://api.github.com/repos/wizzie-io/prozzie/releases | jq -j 'first(.[] | select(.prerelease==true) | .tag_name)'"); then
        printf "Error to check latest prozzie prerelease in github\\n" >&2
        return 1
    fi

    printf "%s\\n" "$latest_prerelease"
}

# Print most recent release in github repository
# Arguments:
# Exit status:
#  Always 0
print_github_last_release () {
    # Get latest github release
    declare latest_release
    if ! latest_release=$(docker run -it cfmanteiga/alpine-bash-curl-jq:latest bash -c "curl --silent https://api.github.com/repos/wizzie-io/prozzie/releases/latest | jq -j '.tag_name'"); then
        printf "Error to check latest prozzie release in github\\n" >&2
        return 1
    fi

    printf "%s\\n" "$latest_release"
}

# Upgrade Prozzie from a origin (i.e: master in git, 1.2.3 from release) with transactional operations
# Arguments:
# Exit status:
upgrade_to_new_version () {
    declare -r new_version="$1"

    # Clear screen
    clear
    # Download selected prozzie release
    log info $'Downloading new release of Prozzie, please wait...\n'
    if ! curl -L -o "/tmp/prozzie-$new_version.tar.gz" "https://github.com/wizzie-io/prozzie/archive/${new_version}.tar.gz"; then
        log error $'An error has been occurred to download the specified prozzie version!\n' >&2
        exit 1
    fi
    # Backup of current prozzie release
    backup_prozzie
    log info $'Upgrading Prozzie release, please wait...\n'
    # Rollback if prozzie upgrade is cancelled
    trap rollback_backup EXIT
    # upgrade prozzie files and version
    if upgrade_prozzie_files "$new_version"; then
        echo "$new_version" > "${PREFIX}"/etc/prozzie/.version
        log ok $'Prozzie has been upgraded successfully to version '"$new_version"$'!\n'
        trap '' EXIT
    else
        log error $'An error has been occurred!\n' >&2
        exit 1
    fi
}

# Create a backup of current Prozzie release files
# Arguments:
# Exit status:
#  Always 0
backup_prozzie () {
    log info $'Creating backup of current prozzie version\n'
    tar -P -zcf "${PREFIX}/var/prozzie/backup/prozzie-$current_release" "${PREFIX}"/share/prozzie "${PREFIX}"/etc/prozzie/.version
}

# Restore Prozzie release stored in ${PROZZIE}/var/prozzie
# Arguments:
# Exit status:
#  Always 0
rollback_backup () {
    log info $'Rollback backup, please wait...\n'
    # Delete all files in ${PREFIX}/share/prozzie directory
    rm -rf "${PREFIX}"/share/prozzie/*
    # Restore backup
    tar -P -zxf "${PREFIX}/var/prozzie/backup/prozzie-$current_release" -C /
    log ok $'Prozzie has been restored!\n'
}

# Replace all necessary Prozzie files from a downloaded Prozzie version
# Arguments:
# Exit status:
#  Always 0
upgrade_prozzie_files () {
    declare -r new_version="$1"
    declare -r target="/tmp/prozzie-$1.tar.gz"

    rm -rf "${PREFIX}"/share/prozzie/*
    log info $'Extracting files...\n'
    tar -zxf "$target" -C /tmp

    bash "/tmp/prozzie-$new_version/update_internal.bash" "${PREFIX}" "/tmp/prozzie-$new_version"
}

main "$@"
