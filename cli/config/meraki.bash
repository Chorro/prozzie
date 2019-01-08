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

. "${PREFIX}/share/prozzie/cli/include/config_compose_no_vars.bash"

##
## @brief      Print a hint to the user about how to send messages to this
##             module.
##
## @return     Always true
##
zz_connector_print_send_message_hint () {
	printf 'Configure "%s:2057/v1/meraki/<validator>" (or '\' "${INTERFACE_IP}"
	printf 'equivalent) under "Network wide > configure > general > '
	printf 'Location and scanning" in your meraki dashboard to make meraki '
	printf 'cloud send location messages. You can check that they are being '
	printf 'received with "prozzie kafka consumer meraki".\n'
}
