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


declare -r SETUP_FILE_SUFFIX='_setup.sh'

function print_table_header () {
	echo '<table><tr><th>ENV</th><th>Default</th><th>Description</th></tr>'
}

function print_table_footer () {
	echo '</table>'
}

# Print zz variable environments of a setup file
# Arguments:
#  File path
function print_envs () {
	. "$1" --source

	local -r MODULE_NAME=${1%_setup.sh}

	echo "<tr><th colspan=\"3\" align=\"center\">$MODULE_NAME</th></tr>"

	for env in "${!module_envs[@]}"; do
		IFS='|' read env_default env_description <<< "${module_envs[$env]}"
		if [[ -z "$env_default" ]]; then
			env_default='(No default)'
		fi
		printf '<tr><td>%s</td><td>%s</td><td>%s</td></tr>\n' "$env" "$env_default" "$env_description"
	done
}

print_table_header

for setup_script in *$SETUP_FILE_SUFFIX; do
	(print_envs "$setup_script")
done

print_table_footer
