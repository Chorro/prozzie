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

# If you source this file in your tests, it will restore prozzie
# version files in every individual test.

tearDown () {
    declare backup_file
    backup_file="$(ls "${PROZZIE_PREFIX}"/var/prozzie/backup/)"

    if [ -f "${PROZZIE_PREFIX}/var/prozzie/backup/$backup_file" ]; then
        tar -P -zxf "${PROZZIE_PREFIX}/var/prozzie/backup/$backup_file" -C /
        rm -rf "${PROZZIE_PREFIX}/var/prozzie/backup/*"
    fi
}
