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

##
## @brief      Tries to get variables from http2k, but it fails since module
##             does not have any. If you call it with no parameters other than
##             module name, it will print a message. If you try to specify a
##             variable, error message will be shown and
##
## @return     0 if no parameter passed, 1 in other case.
##
zz_connector_get_variables () {
	shift  # Module name
	declare -r error_msg='http2k module does not have any variables'
	if [[ $# -gt 0 ]]; then
		printf '%s' "$error_msg" >&2
		return 1
	fi
	printf '%s' "$error_msg"
}

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=()

showVarsDescription () {
    printf '\tNo vars description\n'
}
