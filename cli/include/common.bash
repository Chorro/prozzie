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

readonly DEFAULT_PREFIX="/usr/local"

# log function
log () {
    # Text colors definition
    declare -r red='\e[1;31m'
    declare -r green='\e[1;32m'
    declare -r yellow='\e[1;33m'
    declare -r white='\e[1;37m'
    declare -r normal='\e[m'

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
func_exists () {
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
