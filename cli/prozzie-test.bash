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


# Script: Forward a specified command to prozzie docker-compose.
# Arguments:
#  (All will be forwarded to docker-compose)
#
# Environment:
#  PREFIX - prozzie config files should be in $PREFIX/etc/prozzie/compose
#
# Out:
#  -
#
# Exit status:
#  -

printShortHelp() {
    printf "Dummy test command\\n"
}

main () {
    printShortHelp
}

main "$@"
