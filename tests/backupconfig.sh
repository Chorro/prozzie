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

declare env_bak
env_bak=$(mktemp)
declare -r env_bak

declare base_env_bak
base_env_bak=$(mktemp)
declare -r base_env_bak

setUp () {
    if [[ -f "${PROZZIE_PREFIX}/etc/prozzie/.env" ]]; then
        cp "${PROZZIE_PREFIX}/etc/prozzie/envs/base.env" "$base_env_bak"
        cp "${PROZZIE_PREFIX}/etc/prozzie/.env" "$env_bak"
    fi
}

tearDown () {
    cp "$base_env_bak" "${PROZZIE_PREFIX}/etc/prozzie/envs/base.env"
    cp "$env_bak" "${PROZZIE_PREFIX}/etc/prozzie/.env"
    "${PROZZIE_PREFIX}/bin/prozzie" up -d
}
