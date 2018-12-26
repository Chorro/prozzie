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

readonly DEFAULT_PREFIX='/usr/local'

# log function
log () {
    # Text colors definition
    declare -r red=$'\e[1;31m'
    declare -r green=$'\e[1;32m'
    declare -r yellow=$'\e[1;33m'
    declare -r white=$'\e[1;37m'
    declare -r normal=$'\e[m'

    case $1 in
        e|error|erro) # ERROR
            printf '[ %sERRO%s ] %s' "${red}" "${normal}" "$2"
        ;;
        i|info) # INFORMATION
            printf '[ %sINFO%s ] %s' "${white}" "${normal}" "$2"
        ;;
        w|warn) # WARNING
            printf '[ %sWARN%s ] %s' "${yellow}" "${normal}" "$2"
        ;;
        f|fail) # FAIL
            printf '[ %sFAIL%s ] %s' "${red}" "${normal}" "$2"
        ;;
        o|ok) # OK
            printf '[  %sOK%s  ] %s' "${green}" "${normal}" "$2"
        ;;
        *) # USAGE
            printf 'Usage: log [i|e|w|f] <message>'
        ;;
    esac
}

# Check function $1 existence
func_exists () {
    declare -f "$1" > /dev/null
}

command_exists () {
    command -v "$1" 2>/dev/null
}

# Read a y/n response and returns true if answer is yes.
#
# @param      [--help] Help text describing what the user is answering (in next
#             parameter)
# @param      Prompt text
#
# @return     True if answer is yes, else false.
#
read_yn_response () {
    declare reply help_text='' possible_answers='Y/n'
    if [[ $# -gt 1 && $1 == '--help' ]]; then
        possible_answers='Y/n/h'
        help_text="$2"
        shift 2
    fi

    while true; do
        read -p "$1 [$possible_answers]: " -n 1 -r reply
        if [[ ! -z $help_text && ( $reply == 'h' || $reply == 'H' ) ]]; then
            printf '\n%s\n' "$help_text"
        else
            break
        fi
    done

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
    declare file_name
    file_name=$(mktemp)
    declare -r file_name
    eval "exec {$1}>${file_name}"
    rm "${file_name}"
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

# Custom `select` implementation
# Pass the choices as individual arguments.
# Output is the chosen item, or "", if the user just pressed ENTER.
zz_select () {
    declare -r invalid_selection_message='Invalid selection. Please try again.\n'
    local item i=0 numItems=$#

    # Print numbered menu items, based on the arguments passed.
    for item; do         # Short for: for item in "$@"; do
        printf '%s\n' "$((++i))) $item"
    done >&2 # Print to stderr, as `select` does.

    # Prompt the user for the index of the desired item.
    while :; do
        printf %s "${PS3-#? }" >&2
        read -r index

        # Make sure that the input is either empty, idx or text.
        [[ -z $index ]] && return  # empty input
        if [[ $index =~ ^-?[0-9]+$ ]]; then
            # Answer is a number
            (( index >= 1 && index <= numItems )) 2>/dev/null || \
                { echo "${invalid_selection_message}" >&2; continue; }
            printf %s "${@: index:1}"
            return
        fi

        # Input is string
        for arg in "$@"; do
            if [[ $arg == "$index" ]]; then
                printf '%s' "$arg"
                return
            fi
        done

        # Non-blank unknown response
        log error "$invalid_selection_message" >&2;
    done
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

##
## @brief      Squeeze contiguous blanks and delete escaped ones from stdin
##
## @return     Squeezed string via stdout
##
squash_spaces () {
    declare -r squash='s/\\\?[[:space:]]\+/ /g'
    declare -r trim_end='s/[[:space:]]\+$//'
    declare -r trim_beg='s/^[[:space:]]\+//'
    sed -z "$squash;$trim_end;$trim_beg"
}

# Fallback cp in case that file is deleted.
# On some systems, copy the temporary file descriptor created by temp_fd will
# give a 'Stale file handle'. This wrapper will fallback to a file copy if that
# is needed
cp () {
    declare opt_index src_file='' dst_file dash_options=y
    # Extract first file name
    for ((opt_index=1;opt_index<=$#;opt_index++)); do

        # Find source file option index
        if [[ "$dash_options" == 'y' && "${!opt_index}" == '-'* ]]; then
            if [[ "${!opt_index}" == '--' ]]; then
                # Beyond this point, only files are allowed
                dash_options=n
            fi

            continue # This option did not contain src or dest files
        fi

        if [[ -z "$src_file" ]]; then
            src_file="${!opt_index}"
        else
            dst_file="${!opt_index}"
            break
        fi
    done


    # If source file is deleted, fallback to dd
    if [[ -L "${src_file}" ]] && \
                        ! realpath -e "${src_file}" >/dev/null 2>&1; then
        dd status='none' if="${src_file}" of="${dst_file}" 2>/dev/null

    else
        /usr/bin/env cp "$@"
    fi
}

# Auto-detect the current IPs of machine
#
# Arguments
#  1 - If "scope global" is used returned IP is the global
#
# Environment
#  -
#
# Out:
#  Autodetected IP
#
# Return code
#  Always 0
autodetect_ip() {
    if [[ "$1" != "scope global" ]]; then
        shift
    fi

    declare inet_line_start='^[[:blank:]]*inet6\?'
    declare ip_addr_chars='[0-9a-f.:]*'

    declare get_interface_cmd="ip route|awk '/default/ {printf \$5}'"

    MAIN_INTERFACE=$(docker run --rm --net=host wizzieio/prozzie-toolbox sh -c "$get_interface_cmd")

    declare get_interface_ip_cmd="ip addr show dev $MAIN_INTERFACE $1 | sed  -n \"/${inet_line_start}/ s%${inet_line_start} \\(${ip_addr_chars}\\).*%\\1%p\""

    docker run --rm --net=host wizzieio/prozzie-toolbox sh -c "$get_interface_ip_cmd"
}

##
## @brief      Pure bash emulator of moreutils sponge. It accumulates all input
##             in memory and prints at the input EOF.
##
## @param 1    File to drop the content
##
## @return     readarray && print value
##
zz_sponge() {
    declare -a lines
    readarray lines && printf "%s" "${lines[@]}" > "$1"
}

##
## @brief      Push a trap action to the prozzie trap stack
##             Wrapper over bash trap that allows to stack actions to a given
##             signal, allowing us to not to override previous established traps
##
## @param      1 The variable to save previous stack
## @param      2 The trap condition
## @param      3 The new trap action
##
## @return     trap return value
## @see        zz_trap_pop
##
zz_trap_push() {
    declare -r stack_var="$1"
    declare -r trap_action="$2"
    declare -r trap_condition="$3"

    declare stack_var_actions=''

    printf -v "$stack_var" '%s' "$(trap -p "${trap_condition}")"

    if [[ -n "${!stack_var}" ]]; then
        # There was a previous trap. Format them to add after ${trap_action}
        # Need to use expr here to make BASH expand it, not an external program
        # shellcheck disable=SC2003
        stack_var_actions=$(expr match "${!stack_var}" \
                                         "trap -- '\\(.*\\)' ${trap_condition}")
        stack_var_actions="; ${stack_var_actions}"
    fi

    # We want to expand stack_var and trap_action now
    # shellcheck disable=2064
    trap "${trap_action}${stack_var_actions}" "${trap_condition}"
}

##
## @brief      Pop the prozzie trap stack, NOT executing the saved action with
##             zz_trap_push.
##
## @param      1 Stack variable previously used with zz_trap_push
##
## @return     Trap return code
##
zz_trap_pop() {
    declare -r stack_var="$1"
    declare -r trap_condition="$2"

    if [[ -n "${!stack_var}" ]]; then
        eval "${!stack_var}"
    else
        trap - "${trap_condition}"
    fi

}

##
## @brief Archive a directory in tar format.
##
## @param  1 Directory to archive
##
## @return `tar` return command
##
tar_directory_to_volume_format () {
    tar c -C "$1" -f - .
}

##
## @brief      Delete a file on a volume
##
## @param      [-f|--force] Do not prompt or return error if
## @param        The long
##
## @return     { description_of_the_return_value }
##
zz_docker_rm_file_on_volume () {
    declare dry_run=n force_arg=''
    eval set -- "$(getopt -o 'f' --long force -- "$@")"

    while true; do
        case $1 in
        -f|--force)
            force_arg=-f
            shift
            ;;
        --)
            shift
            break
            ;;
        esac
    done

    declare -r volume="$1"
    declare -r file="$2"

    zz_toolbox_exec \
            --mount "type=volume,source=${volume},target=/dest_v" \
            --workdir "/dest_v" \
            -- rm ${force_arg:-} "${file}"
}

##
## @brief  Copy file from the host is tunning CLI to a given volume
## @param  [--dry-run] Do not make an actual copy of the file, only check that
##         it is possible.
## @param  [--mode=<unix mode>] Mode to copy. Only valid in file mode.
## @param  1 Allowed sources (File, Directory, Volume)
## @param  2 Source Source file, directory, or volume to copy.
## @param  3 Destination volume to add source file. Can use volume:dst to
##           specify file, or volume:dst/ to save the file in that directory.
##           Need to be explicit with final / to add to directory; otherwise,
##           an error is raised.
##
## @return True if can make the copy, false otherwise.
##
zz_docker_copy_file_to_volume () {
    declare dry_run=n
    eval set -- "$(getopt -o '' --long mode:,dry-run -- "$@")"

    while true; do
        case $1 in
        --mode)
            declare -r file_mode="${2}";
            shift 2
            ;;
        --dry-run)
            declare dry_run=y
            shift
            ;;
        --)
            shift
            break
            ;;
        esac
    done

    declare -r source="$2"
    declare -r destination="$3"
    declare origin_type origin_f=n origin_d=n origin_v=n
    for origin_type in f d v; do
        if [[ "$1" == *"$origin_type"* ]]; then
            printf -v "origin_${origin_type}" y
        fi
    done

    # Sadly, there is not a more elegant way to copy stuff to a volume than
    # through a container...
    if [[ "$origin_v" == y ]] && \
                                docker volume ls -q | grep -xq "${source}"; then
        if [[ $dry_run == y ]]; then
            return
        fi

        zz_toolbox_exec \
            --mount "type=volume,source=${source},target=/from" \
            --mount "type=volume,source=${destination},target=/dest_v" \
            -- rsync -a /from/ /dest_v/
        return  # $?
    elif [[ "$origin_d" == y && -d "${source}" ]]; then
        if [[ $dry_run == y ]]; then
            # Check if we can actually compress the directory
            tar_directory_to_volume_format "$2" >/dev/null
            return  # $?
        fi

        tar_directory_to_volume_format "$2" | zz_toolbox_exec -i \
            --mount "type=volume,source=${destination},target=/dest_v" \
            --workdir "/dest_v" \
            -- /bin/tar x -f -
        return  # $?
    elif [[ "$origin_f" == y && -f "${source}" ]]; then
        if [[ $dry_run == y ]]; then
            return
        fi

        declare destination_volume="${destination%:*}"

        declare destination_name
        if [[ $destination == *:* ]]; then
            # User provides a file after volume name
            destination_name="${destination##*:}"
        else
            destination_name="$(basename "${source}")"
        fi

        if ! zz_toolbox_exec -i \
                --mount \
                    "type=volume,source=${destination_volume},target=/dest_v" \
                --workdir '/dest_v' \
                -- /usr/bin/tee \
                "${destination_name}" < "${source}" >/dev/null; then
            return 1
        fi

        if [[ -v file_mode ]] && \
                ! zz_toolbox_exec \
                --mount \
                    "type=volume,source=${destination_volume},target=/dest_v" \
                --workdir '/dest_v' \
                -- /bin/chmod "${file_mode}" "${destination_name}"; then
            return 1
        fi

        return 0
    fi

    return 1
}

##
## @brief      Run a command in prozzie toolbox container. Need to separate
##             prozzie options of command arguments with '--'. First parameter
##             after -- is the docker entrypoint.
##
## @return     Command return code
##
zz_toolbox_exec () {
    declare -r prozzie_toolbox_sha=4bbb390774d32a81a2781b4bce42d69f5bd5af4ac3f87200f2ffb8135ce5da0b
    declare -a docker_options

    while :; do
        declare opt="$1"
        shift

        case "$opt" in
            --) unset -v opt; break ;;
            *) docker_options+=("$opt") ;;
        esac
    done

    declare -r entrypoint="$1"
    shift

    docker run --rm "${docker_options[@]}" --entrypoint "${entrypoint}" \
        -- "wizzieio/prozzie-toolbox@sha256:${prozzie_toolbox_sha}" "$@"
}
