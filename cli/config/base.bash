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

# Import connector functions, overriding some function after this
. "${PREFIX}/share/prozzie/cli/include/config_compose.bash"

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=(
	[ZZ_HTTP_ENDPOINT]='|Data HTTPS endpoint URL (use http://.. for plain HTTP)'
	[INTERFACE_IP]='|Interface IP address '
	[CLIENT_API_KEY]='|Client API key ')

showVarsDescription () {
    printf '\t%-40s%s\n' 'ZZ_HTTP_ENDPOINT' 'HTTPS endpoint URL'
    printf '\t%-40s%s\n' 'INTERFACE_IP' 'Interface IP address'
    printf '\t%-40s%s\n' 'CLIENT_API_KEY' 'Client API key'
}

##
## @brief      Simple wrapper for zz_get_vars, using base env file. Need
##             PREFIX environment variable to know where to find envs file.
##
zz_connector_get_variables () {
	zz_get_vars "${PREFIX}/etc/prozzie/.env" "${@:2}"
}

##
## @brief      Simple wrapper for zz_set_vars, using base env path. Need
##             PREFIX environment variable to know where to find envs file.
##
zz_connector_set_variables () {
	zz_set_vars "${PREFIX}/etc/prozzie/.env" "${@:2}"
}
