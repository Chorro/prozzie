#!/usr/bin/env bash

# This file is part of Prozzie - The Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018-2019 Wizzie S.L.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

. "${PREFIX}/share/prozzie/cli/include/config_compose.bash"

# This variable is intended to be imported, so we don't use this variable here
# shellcheck disable=SC2034
declare -A module_envs=(
	[HTTP_TLS_KEY_FILE]='|Private key to use (blank for plain http)'
	[HTTP_TLS_CERT_FILE]='|Certificate to export (blank for plain http)'
	[HTTP_TLS_CLIENT_CA_FILE]='|Certificate Authority for clients (blank for no client verification)'
	[HTTP_TLS_KEY_PASSWORD]='|Password to decrypt key (blank for no password)')

zz_connector_var_meta_set HTTP_TLS_KEY_FILE unset_blank y
zz_connector_var_meta_set HTTP_TLS_CERT_FILE unset_blank y
zz_connector_var_meta_set HTTP_TLS_KEY_PASSWORD unset_blank y
zz_connector_var_meta_set HTTP_TLS_CLIENT_CA_FILE unset_blank y

##
## @brief  Generic function to get key or certificate file from user
##
## @param  [--dry-run] Do not make any actual change, just validate input.
## @param  1 Print return value
## @param  2 User provided input
##
## @return True if empty or a valid file, false otherwise
##
tls_file_sanitize() {
	declare dry_run_arg rc=1
	eval set -- "$(getopt -o '' --long dry-run -- "$@")"

	while true; do
		case "$1" in
			--dry-run)
				declare -r dry_run_arg=--dry-run
				shift
				;;
			--)
				shift
				break
				;;
		esac
	done

	declare -r return_value="$1"
	declare -r input="$2"

	declare -r tls_data_volume="prozzie_http2k_tls_data"
	# Use of docker volume output redirection for obtain grep exit status

	if [[ "${input}" == "${return_value}" ]]; then
		# No change
		printf '%s' "${input}"
		return 0
	elif [[ -z "${input}" ]]; then
		# Delete previous file
		if [[ -v dry_run_arg ]]; then
			return 0
		fi

		zz_docker_rm_file_on_volume "${tls_data_volume}" \
										-f "${return_value##*/}"; rc=$?
	elif zz_docker_copy_file_to_volume ${dry_run_arg:-} --mode 0400 \
				   'f' "${input}" "${tls_data_volume}:${return_value##*/}"; then
		printf '%s' "$return_value"
		rc=0
	fi

	if [[ $rc -ne 0 ]]; then
		{
			printf 'Invalid value %s! Please specify either ' "$2"
			printf '"%s", blank for disable tls, or a valid ' "${return_value}"
			printf 'system file\n'
		} >&2
	elif [[ -z $dry_run_arg ]]; then
		"${PREFIX}"/bin/prozzie compose rm -s -f http2k 2>&1 | \
				grep -v 'No such service: http2k' >&2
	fi

	return $rc
}

##
## @brief      Make proper treatment of private https TLS key
##
## @param [--dry-run]  Do not make any actual change
## @param 1            User introduced value
##
## @return     True if valid, false otherwise
##
HTTP_TLS_KEY_FILE_sanitize () {
	tls_file_sanitize '/run/secrets/key' "$@"
}

##
## @brief      Make proper treatment of https TLS certificate
##
## @param [--dry-run]  Do not make any actual change
## @param 1            User introduced value
##
## @return     True if valid, false otherwise
##
HTTP_TLS_CERT_FILE_sanitize () {
	tls_file_sanitize '/run/secrets/cert' "$@"
}

##
## @brief      Make proper treatment of https TLS client CA certificate
##
## @param [--dry-run]  Do not make any actual change
## @param 1            User introduced value
##
## @return     True if valid, false otherwise
##
HTTP_TLS_CLIENT_CA_FILE_sanitize () {
	tls_file_sanitize '/run/secrets/cert.client' "$@"
}

##
## @brief      Print a hint to the user about how to send messages to this
##             module.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	if [[ "${module_envs[HTTP_TLS_KEY_FILE]%|*}" == '' ]]; then
		declare -r proto='http'
	else
		declare -r proto='https'
	fi

	printf 'Use "curl -d '\''{"test":1,"timestamp":1518086046}'\'
	printf ' %s://%s:7980/v1/data/testtopic" to ' "${proto}" "${INTERFACE_IP}"
	printf 'produce a message to topic testtopic. You can check that message'
	printf 'reception with "prozzie kafka consumer testtopic".\n'
}
