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
#

##
## @brief      Test help when user press "H" in setup IP auto-detection.
##
test_ip_address_help () {
	set -e
	cd ../setups
	if ! ../tests/tests_setup_cancel_01helpIP.py ./linux_setup.sh; then
		${_FAIL_} \''Help about INTERFACE_IP'\'
	fi
}


. test_run.sh
