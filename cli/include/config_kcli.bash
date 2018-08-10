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


# This file contains the module functionality to handle compose connectors. If a
# connector is based on a compose file yaml, should include this file and update
# functions accordilly

# This file handles the connectors based on docker compose, and defines the
# functions needed to use them.

##
## @brief      Get kafka connect connector variables, using kcli container for
##             kafka connect modules. Variables will be printed via stdout.
##
## @param      1 - Module name to ask kafka connect for.
## @param      @ - Keys to ask for. If empty, all keys=values will be returned.
##
## @return     kcli get "module" return code.
##
zz_connector_get_variables () {
	declare -r module="$1"
	shift

	if [[ $# -eq 0 ]]; then
            "${PREFIX}"/bin/prozzie kcli get "$module"
            return $?
    fi

    declare vars
    vars=$(str_join '|' "$@")
    declare -r vars

    "${PREFIX}"/bin/prozzie kcli get "$module"|grep -P "^(${vars})=.*$"|while read -r line; do printf '%s\n' "${line#*=}"; done
}

##
## @brief      Show a kafka connect message error indicating how to configure
##             kafka connect modules properly.
##
## @return     Always error.
## @todo       Wrap kcli properly
##
zz_connector_set_variables () {
    {
        printf 'Please use next commands in order to '
        printf 'configure %s:\n' "${module}"
        printf 'prozzie kcli rm %s\n' "${module}"
        printf 'prozzie config setup %s\n' "${module}"
    } >&2

    return 1
}
