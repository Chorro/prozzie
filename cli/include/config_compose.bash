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

##
## @brief      Simple wrapper for zz_get_vars, using proper env path. Need
##             PREFIX environment variable to know where to find envs file.
##
zz_connector_get_variables () {
	zz_get_vars "${PREFIX}/etc/prozzie/envs/$1.env" "${@:2}"
}
