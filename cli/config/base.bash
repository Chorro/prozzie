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
	[HTTP_ENDPOINT]='|Data HTTPS endpoint URL (use http://.. for plain HTTP)'
	[INTERFACE_IP]='|Interface IP address'
	[HTTP_POST_PARAMS]='|Client API key')

zz_connector_var_meta_set INTERFACE_IP is_dot_env y

##
## @brief      NO-OP, since user can't disable base connector via CLI.
##
## @return     Always true
##
zz_connector_enable () {
	:
}

##
## @brief      Forbids disable base connector.
##
## @return     Always error
##
zz_connector_disable () {
	# Same effect
	printf 'Base module cannot be disabled\n' >&2
	return 1
}

## @brief      Print a hint to the user about how to send messages to this
##             module.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Use "prozzie kafka produce <mytopic>" to produce a test kafka '
	printf 'message. You can check it'\''s reception with '
	printf '"prozzie kafka consume <mutopic>"\n'
}

##
## @brief  Add protocol (http://) and URI to k2http endpoint
## @param  [--dry-run] Ignored, only to comply with interface
## @param  1 User-introduced value
##
## @return Always true
##
HTTP_ENDPOINT_sanitize() {
	if [[ $1 == --dry-run ]]; then
		shift
	fi

	declare out="$1"
	if [[ ! "$out" =~ ^http[s]?://* ]]; then
		declare out="https://${out}"
	fi
	if [[ ! "$out" =~ /v1/data[/]?$ ]]; then
		declare out="${out}/v1/data"
	fi
	printf "%s" "$out"
}

##
## @brief  k2http expect POST parameters to be in this format
## @param  [--dry-run] Ignored, only to comply with interface
## @param  1 User-introduced value
##
## @return Always true
##
HTTP_POST_PARAMS_sanitize() {
	if [[ $1 == --dry-run ]]; then
		shift
	fi

    declare out="$1"
    if [[ $out != "apikey:"* ]]; then
        out="apikey:$out"
    fi
    printf "%s" "$out"
}

##
## @brief      Prints the docker (prozzie) host external IP4, as seen by the
##             command `ip`.
##
## @return     Always true, except in child commands fatal.
##
INTERFACE_IP_hint() {
  autodetect_ip "scope global"
}
