#!/usr/bin/env bash

declare -r PROZZIE_PREFIX=/opt/prozzie
declare -r INTERFACE_IP="a.b.c.d"

. backupconfig.sh
. base_tests_config.bash

. "${PROZZIE_PREFIX}/share/prozzie/cli/include/common.bash"

#--------------------------------------------------------
# TEST PROZZIE CONFIG OPTIONS
#--------------------------------------------------------

testBasicHelp() {
    # prozzie config must show help with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config
}

testConfigCommandHelp() {
    # prozzie config --help must show help with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config --help
}

testDescribeAll() {
    # prozzie config describe-all must describe all modules with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config describe-all
}

#--------------------------------------------------------
# TEST BASE MODULE
#--------------------------------------------------------

testSetupBaseModuleVariables() {
    # Try to change via setup
    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'my.test.endpoint' \
        "Interface IP address" \
            "${INTERFACE_IP}" \
        'Client API key' \
            'myApiKey'

    ${_ASSERT_TRUE_} '"prozzie config setup base must done with no failure"' $?

    genericTestModule 3 base 'ZZ_HTTP_ENDPOINT=https://my.test.endpoint/v1/data' \
                             "INTERFACE_IP=${INTERFACE_IP}" \
                             'CLIENT_API_KEY=myApiKey'

    "${PROZZIE_PREFIX}"/bin/prozzie config set base \
        ZZ_HTTP_ENDPOINT=my.super.test.endpoint \
        INTERFACE_IP=${INTERFACE_IP} \
        CLIENT_API_KEY=mySuperApiKey

    genericTestModule 3 base 'ZZ_HTTP_ENDPOINT=https://my.super.test.endpoint/v1/data' \
                             "INTERFACE_IP=${INTERFACE_IP}" \
                             'CLIENT_API_KEY=mySuperApiKey'
}

#--------------------------------------------------------
# TEST F2K MODULE
#--------------------------------------------------------

testSetupF2kModuleVariables() {
    genericSetupQuestionAnswer f2k \
        "JSON object of NF probes (It's recommend to use env var)" \
            '\{\}' \
        'Topic to produce netflow traffic?' \
            'flow'

    genericTestModule 2 f2k 'NETFLOW_KAFKA_TOPIC=flow' \
                            'NETFLOW_PROBES={}'

    "${PROZZIE_PREFIX}"/bin/prozzie config set f2k \
        NETFLOW_PROBES='{"keyA":"valueA","keyB":"valueB"}' \
        NETFLOW_KAFKA_TOPIC=myFlowTopic

    genericTestModule 2 f2k  'NETFLOW_PROBES={"keyA":"valueA","keyB":"valueB"}' \
                             'NETFLOW_KAFKA_TOPIC=myFlowTopic'
}

#--------------------------------------------------------
# TEST MONITOR MODULE
#--------------------------------------------------------

##
## @brief      Assert that topic exists and there are one message in it
##
## @param      1 - Topic to check
##
## @return     Always true, exit if not
##
assert_one_message_in_topic() {
    while ! "${PROZZIE_PREFIX}/bin/prozzie" kafka topics --list | \
                                                             grep -xq "$1"; do
            :
    done

    ${_ASSERT_EQUALS_} "'Incorrect number of messages in topic $1'" \
        '1' "$("${PROZZIE_PREFIX}/bin/prozzie" kafka consume "$1" \
        --from-beginning --max-messages 1 | grep -o -E '{.+}' | wc -l)"
}

##
## @brief      Sends a test snmp trap.
##
## @param      1 Destination host
##
## @return     Always true, shunit fail otherwise
##
send_snmp_trap () {
    declare -r destination="$1"

    if ! snmptrap \
            -v 2c \
            -c public \
            "${destination}" \
            "" \
            1.3.6.1.4.1.2021.13.991 \
            .1.3.6.1.2.1.1.6 \
            s "Device in Wizzie"; then
        ${_FAIL_} '"snmptrap command failed"'
    fi
}

testSetupMonitorModuleVariables() {
    declare mibs_directory mibs_directory2
    mibs_directory=$(mktemp -d)
    mibs_directory2=$(mktemp -d)
    declare -r mibs_directory mibs_directory2

    genericSetupQuestionAnswer monitor \
       'monitor custom mibs path (use monitor_custom_mibs for no custom mibs)' \
         "${mibs_directory}" \
       'Topic to produce monitor metrics' 'monitor' \
       'Seconds between monitor polling' '25' \
       'Monitor agents array' "\\'\\'"

    genericTestModule 4 monitor "MONITOR_CUSTOM_MIB_PATH=${mibs_directory}" \
                                'KAFKA_TOPIC=monitor' \
                                'REQUESTS_TIMEOUT=25' \
                                "SENSORS_ARRAY=''"

    while ! /opt/prozzie/bin/prozzie logs monitor | \
                                            grep -q 'Listening for traps'; do
        :;
    done
    send_snmp_trap "${HOSTNAME}"
    assert_one_message_in_topic monitor

    "${PROZZIE_PREFIX}"/bin/prozzie config set monitor \
        MONITOR_CUSTOM_MIB_PATH="${mibs_directory2}" \
        KAFKA_TOPIC=myMonitorTopic \
        REQUESTS_TIMEOUT=60 \
        SENSORS_ARRAY="''"

    genericTestModule 4 monitor "MONITOR_CUSTOM_MIB_PATH=${mibs_directory2}" \
                                'KAFKA_TOPIC=myMonitorTopic' \
                                'REQUESTS_TIMEOUT=60' \
                                "SENSORS_ARRAY=''"

    while ! /opt/prozzie/bin/prozzie logs monitor | \
                                            grep -q 'Listening for traps'; do
        :;
    done

    send_snmp_trap "${HOSTNAME}"
    assert_one_message_in_topic myMonitorTopic
}

#--------------------------------------------------------
# TEST SFACCTD MODULE
#--------------------------------------------------------

testSetupSfacctdModuleVariables() {
    genericSetupQuestionAnswer sfacctd \
         'sfacctd aggregation fields' 'a,b,c,d' \
         'Topic to produce sflow traffic' 'pmacct' \
         'Normalize sflow based on sampling' 'true'

    genericTestModule 3 sfacctd 'SFLOW_AGGREGATE=a,b,c,d' \
                                'SFLOW_KAFKA_TOPIC=pmacct' \
                                'SFLOW_RENORMALIZE=true'

    "${PROZZIE_PREFIX}"/bin/prozzie config set sfacctd \
        SFLOW_AGGREGATE="a,b,c,d,e,f,g,h" \
        SFLOW_KAFKA_TOPIC=mySflowTopic \
        SFLOW_RENORMALIZE=false \

    genericTestModule 3 sfacctd 'SFLOW_AGGREGATE=a,b,c,d,e,f,g,h' \
                                'SFLOW_KAFKA_TOPIC=mySflowTopic' \
                                'SFLOW_RENORMALIZE=false'
}

#--------------------------------------------------------
# TEST MERAKI MODULE
#--------------------------------------------------------

##
## @brief      Send a meraki message and checks that it is received via kafka.
##
## @param      1 Meraki POST message
## @param      2 Number of messages expected. Only the last will be checked
## @param      3 Kafka message expected in position $2
##
## @return     { description_of_the_return_value }
##
send_meraki_msg() {
    declare recv_kafka_messages

    ${_ASSERT_EQUALS_} '"Not valid meraki validator returned"' \
        "'$(curl http://localhost:2057/v1/meraki/validator)'" "'validator'"

    curl -v -d "$1" "http://localhost:2057/v1/meraki/validator"

    recv_kafka_messages=$("${PROZZIE_PREFIX}/bin/prozzie" kafka consume meraki \
        --from-beginning --max-messages "$2" | tail -n 1)
    ${_ASSERT_EQUALS_} '"Wrong message recieved via meraki"' \
        "'$3'" "'${recv_kafka_messages}'"
}

testMeraki() {
    "${PROZZIE_PREFIX}/bin/prozzie" config setup meraki

    # After setup, we must be able to send and receive meraki messages
    declare -r meraki_message1='{"test":1}{"test":2}'
    declare -r meraki_message2='{"test":1}{"test":2}{"test":3}'

    send_meraki_msg "$meraki_message1" 1 '{"test":1}'

    # We should not be able to send messages when disabled. Actual error is
    # "can't resolve prozzie_meraki_1" if we try curl, so we will not test it.
    "${PROZZIE_PREFIX}/bin/prozzie" config disable meraki

    # We should be able to send messages when enabled again
    "${PROZZIE_PREFIX}/bin/prozzie" config enable meraki
    send_meraki_msg "$meraki_message2" 5 '{"test":3}'
}

#--------------------------------------------------------
# TEST MQTT MODULE
#--------------------------------------------------------

testSetupMqttModuleVariables() {
    genericSetupQuestionAnswer mqtt \
         'MQTT Topics to consume' '/my/mqtt/topic' \
         "Kafka's topic to produce MQTT consumed messages" 'mqtt' \
         'MQTT brokers' 'my.broker.mqtt:1883'

    ${_ASSERT_TRUE_} '"prozzie config setup mqtt must done with no failure"' $?

    while ! docker inspect --format='{{json .State.Health.Status}}' \
                    prozzie_kafka-connect_1| grep healthy >/dev/null; do :; done

    genericTestModule 15 mqtt 'name=mqtt' \
                              'mqtt.qos=1' \
                              'mqtt.connection.retries=60' \
                              'key.converter=org.apache.kafka.connect.storage.StringConverter' \
                              'value.converter=org.apache.kafka.connect.storage.StringConverter' \
                              'mqtt.server_uris=my.broker.mqtt:1883' \
                              'mqtt.topic=/my/mqtt/topic' \
                              'kafka.topic=mqtt' \
                              'tasks.max=1' \
                              'message_processor_class=com.evokly.kafka.connect.mqtt.sample.StringProcessor' \
                              'mqtt.client_id=my-id' \
                              'connector.class=com.evokly.kafka.connect.mqtt.MqttSourceConnector' \
                              'mqtt.clean_session=true' \
                              'mqtt.keep_alive_interval=60' \
                              'mqtt.connection_timeout=30'
}

#--------------------------------------------------------
# TEST SYSLOG MODULE
#--------------------------------------------------------

testSetupSyslogModuleVariables() {
    ${_ASSERT_TRUE_} '"prozzie config setup syslog must done with no failure"' \
        "'\"${PROZZIE_PREFIX}\"/bin/prozzie config setup syslog'"

    while ! docker inspect --format='{{json .State.Health.Status}}' prozzie_kafka-connect_1| grep healthy >/dev/null; do :; done

    genericTestModule 11 syslog 'name=syslog' \
                                'key.converter=org.apache.kafka.connect.json.JsonConverter' \
                                'value.converter=org.apache.kafka.connect.json.JsonConverter' \
                                'syslog.structured.data=true' \
                                'kafka.topic=syslog' \
                                'tasks.max=1' \
                                'syslog.port=1514' \
                                'syslog.host=0.0.0.0' \
                                'key.converter.schemas.enable=false' \
                                'connector.class=com.github.jcustenborder.kafka.connect.syslog.UDPSyslogSourceConnector' \
                                'value.converter.schemas.enable=false'
}

#--------------------------------------------------------
# TEST RESILIENCE
#--------------------------------------------------------

testDescribeWrongModule() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config describe wrongModule; then
        ${_FAIL_} '"prozzie config describe wrongModule must show error"'
    fi
}

testWrongOption() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --wrongOption; then
        ${_FAIL_} '"prozzie config --wrongOption must show error"'
    fi
}

testWrongAction() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config wrongAction; then
        ${_FAIL_} '"prozzie config wrongAction must show error"'
    fi
}

##
## @brief      Test to set a wrong variable with prozzie config set
##
## @param      1 Args modifier, to be able to add and remove arguments of the
##               set
##
## @return     Always true
##
x_testSetWrongVariable() {
    declare args_modifier=$1
    declare base_md5sum_pre f2k_md5sum_pre
    declare -ar wrongCommands=(
        # First variable valid, other invalid: `prozzie config set should not
        # change anything even if some of them are valid
        'base INTERFACE_IPV4=1.2.3.4 HTTP_ENDPOINT=my.super.test.endpoint'
        # First variable valid, other invalid: `prozzie config set should not
        # change anything even if some of them are valid
        'base CLIENT_API_KEY=1234 INTERFACE_IPV4=1.2.3.4 HTTP_ENDPOINT=my.super.test.endpoint'
        # Wrong variable formar
        'base VAR_WITH_NO_VALUE'
        # Unknown variable in module ! base
        'f2k BLABLA=bleble'
        'f2k NETFLOW_KAFKA_TOPIC=titi BLABLA=bleble'
        # Wrong module
        'wrongModule MYVAR=myval'
        )

    "${PROZZIE_PREFIX}/bin/prozzie" config enable f2k

    base_md5sum_pre=$(md5sum ${PROZZIE_PREFIX}/etc/prozzie/.env)
    f2k_md5sum_pre=$(md5sum ${PROZZIE_PREFIX}/etc/prozzie/envs/f2k.env)
    declare -r base_md5sum_pre f2k_md5sum_pre

    for args in "${wrongCommands[@]}"; do
        # Want argument splitting here
        # shellcheck disable=2086
        args="$($args_modifier $args)"
        printf 'Testing prozzie config set %s\n' "$args"
        # shellcheck disable=2086
        if "${PROZZIE_PREFIX}"/bin/prozzie config set $args; then
            ${_FAIL_} \
                '"prozzie config set must show error if keys are not recognized"'
        fi

        ${_ASSERT_EQUALS_} \
            '"prozzie config set invalid variable changed env file"' \
            "'$base_md5sum_pre'" \
            "'$(md5sum ${PROZZIE_PREFIX}/etc/prozzie/.env)'"

        ${_ASSERT_EQUALS_} \
            '"prozzie config set invalid variable changed env file"' \
            "'$f2k_md5sum_pre'" \
            "'$(md5sum ${PROZZIE_PREFIX}/etc/prozzie/envs/f2k.env)'"

        # Check that anything change
        genericTestModule 3 base 'ZZ_HTTP_ENDPOINT=https://localhost/v1/data' \
                                 "INTERFACE_IP=${HOSTNAME}" \
                                 'CLIENT_API_KEY=prozzieapi'
    done
}

add_dry_run_after_module() {
    printf '%s ' "$1"
    printf '%s ' '--dry-run'
    printf '%s ' "${@:1}"
}

identity_function() {
    printf '%s ' "$@"
}

append_dry_run() {
    printf '%s ' '--dry-run '; printf '%s ' "$@"
}


testSetWrongVariable() {
    x_testSetWrongVariable identity_function
    x_testSetWrongVariable append_dry_run
    x_testSetWrongVariable add_dry_run_after_module
}

testSetNoReloadProzzie() {
    "${PROZZIE_PREFIX}"/bin/prozzie config set --no-reload-prozzie \
        base CLIENT_API_KEY=notreloadedapi

    if ! grep -xq 'CLIENT_API_KEY=notreloadedapi' \
                                      "${PROZZIE_PREFIX}/etc/prozzie/.env"; then
        ${_FAIL_} '"Variable not changed in env file"'
    fi

    if ! docker inspect prozzie_k2http_1 | \
                        grep -q 'HTTP_POST_PARAMS=apikey:prozzieapi' || \
                        docker inspect prozzie_k2http_1 | \
                        grep -q 'HTTP_POST_PARAMS=apikey:notreloadedapi'; then
        ${_FAIL_} '"Variable reloaded in container"'
    fi
}

testGetWrongModuleConfiguration() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config get wrongModule; then
        ${_FAIL_} '"prozzie config get must show error if module does not have an associated .env file"'
    fi
}

testWrongModule() {
    touch "${PROZZIE_PREFIX}"/etc/prozzie/envs/wrongModule.env

    if "${PROZZIE_PREFIX}"/bin/prozzie config get wrongModule; then
        ${_FAIL_} '"prozzie config get must show error if module does not have an configuration file"'
    fi

    rm -rf "${PROZZIE_PREFIX}"/etc/prozzie/envs/wrongModule.env
}

testDescribeMustShowHelpIfModuleIsNotPresent() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config describe; then
        ${_FAIL_} '"prozzie config describe must show help with failure"'
    fi
}

testSetupMustShowHelpIfModuleIsNotPresent() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config setup; then
        ${_FAIL_} '"prozzie config setup must show help with failure"'
    fi
}

testConfigMustShowErrorIfModuleIsNotExist() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config get wrongModule; then
        ${_FAIL_} '"prozzie config get wrongModule must show error"'
    fi
}

testConfigMustShowHelpIfTryToSetMqttAndSyslogModules() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config set mqtt kafka.topic=myTopic; then
        ${_FAIL_} '"prozzie config set mqtt kafka.topic=myTopic must show help"'
    fi
    if "${PROZZIE_PREFIX}"/bin/prozzie config set syslog kafka.topic=myTopic; then
        ${_FAIL_} '"prozzie config set syslog kafka.topic=myTopic must show help"'
    fi
}

testSetupCancellation() {
    declare md5sum_file temp_file
    temp_file=$(mktemp)
    declare -r temp_file
    exec {md5sum_file}>"${temp_file}"
    rm "${temp_file}"


    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'blah.blah.blah' \
        'Interface IP address' 'blah.blah.blah.blah' \
        'Client API key' 'blahblahblah'

    md5sum "${PROZZIE_PREFIX}"/etc/prozzie/.env > "/dev/fd/${md5sum_file}"

    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'https://my.test.endpoint' \
        'Interface IP address' "${INTERFACE_IP}" \
        'Client API key' '\x03'

    ${_ASSERT_TRUE_} "\".ENV file mustn\\'t be modified\"" \
                                            "'md5sum -c \"/dev/fd/${md5sum_file}\"'"

    genericSetupQuestionAnswer base \
        'Data HTTPS endpoint URL (use http://.. for plain HTTP)' \
            'https://my.test.endpoint' \
        'Interface IP address' "${INTERFACE_IP}" \
        'Client API key' 'mySuperApiKey'

    if md5sum -c "/dev/fd/${md5sum_file}"; then
        ${_FAIL_} "\".ENV file must be modified\""
    fi
}

#--------------------------------------------------------
# TEST WIZARD
#--------------------------------------------------------

testWizard() {
    genericSpawnQuestionAnswer "${PROZZIE_PREFIX}/bin/prozzie config wizard" \
         'Do you want to configure modules? (Enter for quit)' '{f2k} {}' \
         'JSON object of NF probes (It'\''s recommend to use env var)' '\{\}' \
         'Topic to produce netflow traffic?' 'wizardFlow'

    genericTestModule 2 f2k 'NETFLOW_KAFKA_TOPIC=wizardFlow' \
                            'NETFLOW_PROBES={}'
}

#--------------------------------------------------------
# TEST ENABLE AND DISABLE MODULES
#--------------------------------------------------------

testEnableModule() {
    declare -r expected_message='{"fieldA": "valueA", "fieldB": 12, "fieldC": true}'
    declare -r connectors=(f2k monitor http2k syslog)
    declare connector

    "${PROZZIE_PREFIX}/bin/prozzie" config enable "${connectors[@]}"

    for connector in "${connectors[@]}"; do
        if ! "${PROZZIE_PREFIX}/bin/prozzie" config list-enabled | \
                                           grep -qx "$connector"; then
            ${_FAIL_} "'$connector not listed in prozzie config list-enabled'"
        fi
    done

    if [[ ! -L "${PROZZIE_PREFIX}/etc/prozzie/compose/f2k.yaml" ]]; then
        ${_FAIL_} '"prozzie config enable must link f2k compose file"'
    fi

    if [[ ! -L "${PROZZIE_PREFIX}/etc/prozzie/compose/monitor.yaml" ]]; then
        ${_FAIL_} '"prozzie config enable must link monitor compose file"'
    fi

    if [[ ! -L "${PROZZIE_PREFIX}/etc/prozzie/compose/http2k.yaml" ]]; then
        ${_FAIL_} '"prozzie config enable must link http2k compose file"'
    fi

    if ! curl -v http://"${HOSTNAME}":7980/v1/data/http2k_topic -H 'X-Consumer-ID:test' -d '{"fieldA": "valueA", "fieldB": 12, "fieldC": true}'; then
        ${_FAIL_} '"HTTP2K must be enabled and running"'
    fi

    ${_ASSERT_EQUALS_} '"Incorrect number of topics for http2k"' \
    '1' "$("${PROZZIE_PREFIX}/bin/prozzie" kafka topics --list | grep test_http2k_topic | wc -w)"

    declare message
    message=$("${PROZZIE_PREFIX}/bin/prozzie" kafka consume test_http2k_topic --from-beginning --max-messages 1|grep -o -E "{.+}")
    declare -r message

    ${_ASSERT_EQUALS_} '"Incorrect expected message"' \
    "'${expected_message}'" "'${message}'"

    if [[ $("${PROZZIE_PREFIX}"/bin/prozzie kcli status syslog | head -n 1 | grep -o 'RUNNING\|PAUSED') == PAUSED ]]; then
        ${_FAIL_} '"Syslog must be enabled and running"'
    fi

    if ! logger "test syslog message" -p local0.info -d -n localhost -P 1514; then
        ${_FAIL_} '"Fail to send syslog message"'
    fi

    ${_ASSERT_EQUALS_} '"Incorrect number of messages in topic syslog"' \
    '1' "$("${PROZZIE_PREFIX}/bin/prozzie" kafka consume syslog --from-beginning --max-messages 1 | grep -o -E '{.+}' | wc -l)"
}

testDisableModule() {
    declare -r connectors=(f2k monitor http2k syslog)

    "${PROZZIE_PREFIX}/bin/prozzie" config disable "${connectors[@]}"

    if "${PROZZIE_PREFIX}/bin/prozzie" config list-enabled | \
                            grep -xq "$(str_join '|' "${connectors[@]}")"; then
        ${_FAIL_} \
            "'Unexpected connector listed in prozzie config list-enabled: \
            $("${PROZZIE_PREFIX}/bin/prozzie" config list-enabled)'"
    fi

    if [[ -L "${PROZZIE_PREFIX}/etc/prozzie/compose/f2k.yaml" ]]; then
        ${_FAIL_} '"prozzie config disable must to unlink f2k compose file"'
    fi

    if [[ -L "${PROZZIE_PREFIX}/etc/prozzie/compose/monitor.yaml" ]]; then
        ${_FAIL_} '"prozzie config disable must to unlink monitor compose file"'
    fi

    if ! snmptrap -v 2c -c public "${HOSTNAME}" "" 1.3.6.1.4.1.2021.13.991 .1.3.6.1.2.1.1.6 s "Device in Wizzie"; then
        ${_FAIL_} '"snmptrap command failed"'
    fi

    ${_ASSERT_EQUALS_} '"Incorrect number of messages in topic test_http2k_topic"' \
    '1' "$("${PROZZIE_PREFIX}/bin/prozzie" kafka consume test_http2k_topic --from-beginning --timeout-ms 500 | grep -o -E '{.+}' | wc -l)"

    if [[ -L "${PROZZIE_PREFIX}/etc/prozzie/compose/http2k.yaml" ]]; then
        ${_FAIL_} '"prozzie config disable must to unlink http2k compose file"'
    fi

    if curl -v http://"${HOSTNAME}":7980/v1/data/http2k_topic -H 'X-Consumer-ID:test' -d '{"fieldA":"valueA", "fieldB": 12, "fieldC": true}'; then
        ${_FAIL_} '"HTTP2K must be disabled and stopped"'
    fi

    if [[ $("${PROZZIE_PREFIX}"/bin/prozzie kcli status syslog | head -n 1 | grep -o 'RUNNING\|PAUSED') == RUNNING ]]; then
        ${_FAIL_} '"Syslog must be disabled and stopped"'
    fi

    if ! logger "test syslog message" -p local0.info -d -n localhost -P 1514; then
        ${_FAIL_} '"Fail to send syslog message"'
    fi

    ${_ASSERT_EQUALS_} '"Incorrect number of messages in topic syslog"' \
    '2' "$("${PROZZIE_PREFIX}/bin/prozzie" kafka consume syslog --from-beginning --max-messages 5 --timeout-ms 500 | grep -o -E '{.+}' | wc -l)"
}

testListEnabledModules() {
    "${PROZZIE_PREFIX}/bin/prozzie" config list-enabled

    # Currently, they are equal: Only difference in "table" header
    if ! diff <("${PROZZIE_PREFIX}/bin/prozzie" config list-enabled | \
                                                grep -v '^Enabled modules:' | \
                                                sort) \
              <("${PROZZIE_PREFIX}/bin/prozzie" config list-enabled -q | \
                                                                    sort); then
        ${_FAIL_} '"prozzie config list-enabled not working properly"'
    fi

    if ! diff <("${PROZZIE_PREFIX}/bin/prozzie" config list-enabled --quiet | \
                                                                        sort) \
              <("${PROZZIE_PREFIX}/bin/prozzie" config list-enabled -q | \
                                                                    sort); then
        ${_FAIL_} '"prozzie config list-enabled -q not equal to --quiet"'
    fi

    # Base module should never be printed here
    if "${PROZZIE_PREFIX}/bin/prozzie" config list-enabled -q | grep base; then
        ${_FAIL_} "'Base compose module listed in \"prozzie config list-enabled\"'"
    fi
}

. test_run.sh
