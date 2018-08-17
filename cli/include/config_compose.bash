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

# Return the location of the module env file. Need PREFIX to be declared.
#
# @param      Module name
#
# @return     Always true
#
connector_env_file () {
	declare -r module="$1"
	if [[ "${1}" == base ]]; then
	  printf "%s/etc/prozzie/.env" "${PREFIX}"
	else
	  printf '%s/etc/prozzie/envs/%s.env' "${PREFIX}" "$module"
	fi
}

##
## @brief      Check if env file exists, calling exit if it does not.
##
## @param      1 env file
##
## @return     Always 0
##
assert_env_file_exists () {
	declare -r env_file="$1"

	if [[ ! -f "$env_file" ]]; then
		printf "Module '%s' does not have a defined configuration (*.env file)\\n" "$module">&2
		printf "You can set '%s' module configuration using setup action.\\n" "$module">&2
		printf 'For more information see the command help\n' >&2
		exit 1
	fi
}

##
## @brief      Acts over env file, asserting that it does exists and forwarding
##             arguments to a callback function
##
## @param      1 - Command callback
## @param      2 - Module name, and env file name
## @param      @ - Other parameters
##
## @return     { description_of_the_return_value }
##
zz_connector_env_handler () {
	declare -r cmd_callback="$1"
	declare -r module="$2"
	declare env_file
	env_file=$(connector_env_file "$module")
	declare -r env_file

	assert_env_file_exists "${env_file}"
	$cmd_callback "${env_file}" "${@:3}"
}

##
## @brief      Simple wrapper for zz_get_vars, using proper env path. Need
##             PREFIX environment variable to know where to find envs file.
##
zz_connector_get_variables () {
	zz_connector_env_handler zz_get_vars "$@"
}

##
## @brief      Simple wrapper for zz_set_vars, using proper env path. Need
##             PREFIX environment variable to know where to find envs file.
##
zz_connector_set_variables () {
	zz_connector_env_handler zz_set_vars "$@"
}

##
## @brief      Wrapper for connector_setup, that ask the user for the different
##             variables needed for the connector.
##
zz_connector_setup () {
	declare -a connector_setup_args
	if [[ $1 == --no-reload-prozzie ]]; then
		connector_setup_args+=(--no-reload-prozzie)
		shift
	fi

	declare -r module="$1"

	# If no args provided, we want to expand to nothing, not empty string.
	# shellcheck disable=SC2068
	connector_setup "$(connector_env_file "$module")" \
					${connector_setup_args[@]} \
					zz_link_compose_file "$@"
}

# Create a symbolic link in prozzie compose directory in order to enable a module
# Arguments:
#  [--no-set-default] Don't set default parameters for specific prozzie module
#  1 - Module to link
# Exit status:
#  0 - Module has been linked
#  1 - An error has ocurred
zz_connector_enable () {
	declare set_default=y

	if [[ $1 == --no-set-default ]]; then
		set_default=n
		shift
	fi

	declare -r module="${1}"
	declare -r from="${PREFIX}"/share/prozzie/compose/${module}.yaml
	declare -r to="${PREFIX}"/etc/prozzie/compose/${module}.yaml

	if [[ $set_default == y && \
						! -f "${PREFIX}"/etc/prozzie/envs/$module.env ]]; then
		zz_set_default "${PREFIX}/etc/prozzie/envs/$module.env"
	fi

	if [[ ! -f "$from" ]]; then
		printf "Can't enable module %s: Can't create symlink %s"'\n' "$module" "$from" >&2
		return 1
	fi

	if ln -s "$from" "$to" 2>/dev/null; then
		printf 'Module %s enabled\n' "$module" >&2
	else
		printf 'Module %s already enabled\n' "$module" >&2
	fi
}

# Destroy a symbolic link in prozzie compose directory in order to disable a module
# Arguments:
#  1 - Module to unlink
# Exit status:
#  Always 0
zz_connector_disable () {
	declare -r module="${1}"
	declare -r target="${PREFIX}"/etc/prozzie/compose/${module}.yaml

	rm "$target" 2>/dev/null \
		&& printf 'Module %s disabled\n' "$module" >&2 \
		|| printf 'Module %s already disabled\n' "$module" >&2
}
