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

. "${BASH_SOURCE%/*}/cli/include/common.bash"

main () {
    declare PREFIX
    PREFIX="$1"
    declare upgrade_path
    upgrade_path="$2"

    log info $'Current installation prefix: '"$PREFIX"$'\n'
    log info $'Upgrade Prozzie from path: '"$upgrade_path"$'\n'

    if [[ -d "$upgrade_path/cli" ]]; then
        log info $'Upgrading prozzie CLI...\n'
        # Delete old directory and its content
        rm -rf "${PREFIX}"/share/prozzie/cli
        # Move new directory and its content
        mv "$upgrade_path/cli" "${PREFIX}"/share/prozzie
    fi

    if [[ -d "$upgrade_path/compose" ]]; then
        log info $'Upgrading prozzie compose files...\n'
        # Delete old directory and its  content
        rm -rf "${PREFIX}"/share/prozzie/compose
        # Move new directory and its content
        mv "$upgrade_path/compose" "${PREFIX}"/share/prozzie
    fi

    # Base env file was created in 0.6.0~0.7.0 range
    if [[ ! -f "${PREFIX}"/etc/prozzie/envs/base.env ]]; then
        log info 'Upgrading prozzie config from pre-0.7.0 format...'$'\n'
        mv -v "${PREFIX}"/etc/prozzie/.env "${PREFIX}"/etc/prozzie/envs/base.env
        grep INTERFACE_IP "${PREFIX}"/etc/prozzie/envs/base.env > \
            "${PREFIX}"/etc/prozzie/.env

        declare -r ZZ_HTTP_ENDPOINT_S='s/^ZZ_HTTP_ENDPOINT=/HTTP_ENDPOINT=/'
        declare -r CLIENT_API_KEY_S='s/^CLIENT_API_KEY=/HTTP_POST_PARAMS=apikey:/'

        sed -i "${ZZ_HTTP_ENDPOINT_S};${CLIENT_API_KEY_S}" -- \
                                           "${PREFIX}"/etc/prozzie/envs/base.env
    fi
}

main "$@"
