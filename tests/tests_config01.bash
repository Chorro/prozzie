#!/usr/bin/env bash

declare -r PROZZIE_PREFIX=/opt/prozzie
declare -r PROZZIE_CLI_CONFIG="${PROZZIE_PREFIX}"/share/prozzie/cli/config
declare -r PROZZIE_CLI_ETC="${PROZZIE_PREFIX}"/etc/prozzie/
declare -r INTERFACE_IP="a.b.c.d"

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
    # prozzie config --describe-all must describe all modules with no failure
    "${PROZZIE_PREFIX}"/bin/prozzie config --describe-all
}

#--------------------------------------------------------
# TEST MODULES VARIABLES AND DESCRIPTIONS
#--------------------------------------------------------

genericTestModule() {
    declare -r num_arguments="$1"
    declare -r module_name="$2"
    shift 2

    declare describe_out="$("${PROZZIE_PREFIX}/bin/prozzie" config -d "$module_name" \
        | grep -v 'Module .*')"
    declare description key

    ${_ASSERT_EQUALS_} '"Incorrect number of arguments"' \
    ${num_arguments} '$(printf "%s\n" "${describe_out}" | wc -l)'

    for key in "$@"; do
    declare expected_value value
        if [[ $key == *'='* ]]; then
            expected_value="${key#*=}"
            key="${key%=*}"
        fi
        description=$(printf '%s\n' "${describe_out}" | grep "${key}")
        # Exists key
        if [[ "${description}" != *"${key}"* ]]; then
                ${_FAIL_} '"key ${key}"'
        fi
        # Exists description
        if [[ "${description}" != *"${key}"* ]]; then
                ${_FAIL_} '"Description ${key}"'
        fi
        # We can ask for that variable
        value=$("${PROZZIE_PREFIX}/bin/prozzie" config "${module_name}" "${key}")
    if [[ -v expected_value ]]; then
        ${_ASSERT_EQUALS_} '"Expected ${key} value"' '"$expected_value"' '"$value"'
    fi
    unset -v value expected_value
    done
}

testBaseModule() {
    genericTestModule 3 base ZZ_HTTP_ENDPOINT INTERFACE_IP CLIENT_API_KEY
}

testF2kModule() {
    genericTestModule 3 f2k NETFLOW_COLLECTOR_PORT NETFLOW_PROBES NETFLOW_KAFKA_TOPIC
}

testMonitorModule() {
    genericTestModule 5 monitor MONITOR_CUSTOM_MIB_PATH MONITOR_TRAPS_PORT \
        MONITOR_KAFKA_TOPIC MONITOR_REQUEST_TIMEOUT MONITOR_SENSORS_ARRAY
}

testMqttModule() {
    genericTestModule 14 mqtt mqtt.server_uris kafka.topic mqtt.topic name \
        connector.class tasks.max key.converter value.converter mqtt.client_id \
        mqtt.clean_session mqtt.connection_timeout mqtt.keep_alive_interval \
        mqtt.qosl message_processor_class
}

testSyslogModule() {
    genericTestModule 11 syslog name connector.class tasks.max key.converter \
        value.converter key.converter.schemas.enable \
        value.converter.schemas.enable kafka.topic syslog.host syslog.port \
        syslog.structured.data
}

testSfacctdModule() {
    genericTestModule 4 sfacctd SFLOW_KAFKA_TOPIC SFLOW_COLLECTOR_PORT \
        SFLOW_RENORMALIZE SFLOW_AGGREGATE
}

#--------------------------------------------------------
# TEST BASE MODULE
#--------------------------------------------------------

testSetupBaseModuleVariables() {
    declare -g ENV_BACKUP=$(<"${PROZZIE_CLI_ETC}"/.env)

    expect -c \
        "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s base
         expect \"Data HTTPS endpoint URL (use http://.. for plain HTTP): \"
         send \"\025my.test.endpoint\r\"
         expect \"Interface IP address : \"
         send \"\025${INTERFACE_IP}\r\"
         expect \"Client API key : \"
         send \"\025myApiKey\r\"
         expect eof
        " >/dev/null 2>&1

    ${_ASSERT_TRUE_} '"prozzie config -s base must done with no failure"' $?
}

testGetBaseModuleVariables() {
    genericTestModule 3 base 'ZZ_HTTP_ENDPOINT=https://my.test.endpoint/v1/data' \
                             "INTERFACE_IP=${INTERFACE_IP}" \
                             'CLIENT_API_KEY=myApiKey'
}

testSetBaseModuleVariables() {
    "${PROZZIE_PREFIX}"/bin/prozzie config base ZZ_HTTP_ENDPOINT my.super.test.endpoint
    "${PROZZIE_PREFIX}"/bin/prozzie config base INTERFACE_IP ${INTERFACE_IP}
    "${PROZZIE_PREFIX}"/bin/prozzie config base CLIENT_API_KEY mySuperApiKey

    genericTestModule 3 base 'ZZ_HTTP_ENDPOINT=https://my.super.test.endpoint/v1/data' \
                             "INTERFACE_IP=${INTERFACE_IP}" \
                             'CLIENT_API_KEY=mySuperApiKey'

    echo "${ENV_BACKUP}" > "${PROZZIE_CLI_ETC}"/.env
}

#--------------------------------------------------------
# TEST F2K MODULE
#--------------------------------------------------------

testSetupF2kModuleVariables() {
    declare -g ENV_BACKUP=$(<"${PROZZIE_CLI_ETC}"/.env)

    expect -c \
        "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s f2k
         expect \"In what port do you want to listen for netflow traffic? :\"
         send \"\0252055\r\"
         expect \"JSON object of NF probes (It's recommend to use env var) :\"
         send \"\025{}\r\"
         expect \"Topic to produce netflow traffic? : \"
         send \"\025flow\r\"
         expect eof
        " >/dev/null 2>&1

    ${_ASSERT_TRUE_} '"prozzie config -s f2k must done with no failure"' $?
}

testGetF2kModuleVariables() {
    genericTestModule 3 f2k 'NETFLOW_COLLECTOR_PORT=2055' \
                            'NETFLOW_KAFKA_TOPIC=flow' \
                            'NETFLOW_PROBES={}'
}

testSetF2kModuleVariables() {
    "${PROZZIE_PREFIX}"/bin/prozzie config f2k NETFLOW_COLLECTOR_PORT 5502
    "${PROZZIE_PREFIX}"/bin/prozzie config f2k NETFLOW_PROBES '{"keyA":"valueA","keyB":"valueB"}'
    "${PROZZIE_PREFIX}"/bin/prozzie config f2k NETFLOW_KAFKA_TOPIC myFlowTopic

    genericTestModule 3 f2k 'NETFLOW_COLLECTOR_PORT=5502' \
                             'NETFLOW_PROBES={"keyA":"valueA","keyB":"valueB"}' \
                             'NETFLOW_KAFKA_TOPIC=myFlowTopic'

    echo "${ENV_BACKUP}" > "${PROZZIE_CLI_ETC}"/.env
}

#--------------------------------------------------------
# TEST MONITOR MODULE
#--------------------------------------------------------

testSetupMonitorModuleVariables() {
    declare -g ENV_BACKUP=$(<"${PROZZIE_CLI_ETC}"/.env)

    expect -c \
        "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s monitor
         expect \"monitor custom mibs path (use monitor_custom_mibs for no custom mibs):\"
         send \"\025my_custom_mibs\r\"
         expect \"Port to listen for SNMP traps:\"
         send \"\025162\r\"
         expect \"Topic to produce monitor metrics:\"
         send \"\025monitor\r\"
         expect \"Seconds between monitor polling:\"
         send \"\02525\r\"
         expect \"Monitor agents array:\"
         send \"\025''\r\"
         expect eof
        " >/dev/null 2>&1

    ${_ASSERT_TRUE_} '"prozzie config -s monitor must done with no failure"' $?
}

testGetMonitorModuleVariables() {
    genericTestModule 5 monitor 'MONITOR_CUSTOM_MIB_PATH=my_custom_mibs' \
                                'MONITOR_TRAPS_PORT=162' \
                                'MONITOR_KAFKA_TOPIC=monitor' \
                                'MONITOR_REQUEST_TIMEOUT=25' \
                                "MONITOR_SENSORS_ARRAY=''"
}

testSetMonitorModuleVariables() {
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_CUSTOM_MIB_PATH /other/mibs/path
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_TRAPS_PORT 621
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_KAFKA_TOPIC myMonitorTopic
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_REQUEST_TIMEOUT 60
    "${PROZZIE_PREFIX}"/bin/prozzie config monitor MONITOR_SENSORS_ARRAY "'a,b,c,d'"

    genericTestModule 5 monitor 'MONITOR_CUSTOM_MIB_PATH=/other/mibs/path' \
                                'MONITOR_TRAPS_PORT=621' \
                                'MONITOR_KAFKA_TOPIC=myMonitorTopic' \
                                'MONITOR_REQUEST_TIMEOUT=60' \
                                "MONITOR_SENSORS_ARRAY='a,b,c,d'"

    echo "${ENV_BACKUP}" > "${PROZZIE_CLI_ETC}"/.env
}

#--------------------------------------------------------
# TEST SFACCTD MODULE
#--------------------------------------------------------

testSetupSfacctdModuleVariables() {
    declare -g ENV_BACKUP=$(<"${PROZZIE_CLI_ETC}"/.env)

    expect -c \
        "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s sfacctd
         expect \"sfacctd aggregation fields:\"
         send \"\025a,b,c,d\r\"
         expect \"In what port do you want to listen for sflow traffic:\"
         send \"\0254363\r\"
         expect \"Topic to produce sflow traffic:\"
         send \"\025pmacct\r\"
         expect \"Normalize sflow based on sampling:\"
         send \"\025true\r\"
         expect eof
        " >/dev/null 2>&1

    ${_ASSERT_TRUE_} '"prozzie config -s sfacctd must done with no failure"' $?
}

testGetSfacctdModuleVariables() {
        genericTestModule 4 sfacctd 'SFLOW_AGGREGATE=a,b,c,d' \
                                    'SFLOW_COLLECTOR_PORT=4363' \
                                    'SFLOW_KAFKA_TOPIC=pmacct' \
                                    'SFLOW_RENORMALIZE=true'
}

testSetSfacctdModuleVariables() {
    "${PROZZIE_PREFIX}"/bin/prozzie config sfacctd SFLOW_AGGREGATE "a,b,c,d,e,f,g,h"
    "${PROZZIE_PREFIX}"/bin/prozzie config sfacctd SFLOW_COLLECTOR_PORT 5544
    "${PROZZIE_PREFIX}"/bin/prozzie config sfacctd SFLOW_KAFKA_TOPIC mySflowTopic
    "${PROZZIE_PREFIX}"/bin/prozzie config sfacctd SFLOW_RENORMALIZE false

    genericTestModule 4 sfacctd 'SFLOW_AGGREGATE=a,b,c,d,e,f,g,h' \
                                'SFLOW_COLLECTOR_PORT=5544' \
                                'SFLOW_KAFKA_TOPIC=mySflowTopic' \
                                'SFLOW_RENORMALIZE=false'

    echo "${ENV_BACKUP}" > "${PROZZIE_CLI_ETC}"/.env
}

#--------------------------------------------------------
# TEST MQTT MODULE
#--------------------------------------------------------
testSetupMqttModuleVariables() {
    expect -c \
        "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s mqtt
         expect \"MQTT Topics to consume:\"
         send \"\025/my/mqtt/topic\r\"
         expect \"Kafka's topic to produce MQTT consumed messages:\"
         send \"\025mqtt\r\"
         expect \"MQTT brokers:\"
         send \"\025my.broker.mqtt:1883\r\"
         expect eof
        " >/dev/null 2>&1

    ${_ASSERT_TRUE_} '"prozzie config -s mqtt must done with no failure"' $?
}

testGetMqttModuleVariables() {
    while ! docker inspect --format='{{json .State.Health.Status}}' prozzie_kafka-connect_1| grep healthy >/dev/null; do :; done

    genericTestModule 14 mqtt 'name=mqtt' \
                              'mqtt.qos=1' \
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
    expect -c \
        "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s syslog
         expect eof
        " >/dev/null 2>&1

    ${_ASSERT_TRUE_} '"prozzie config -s syslog must done with no failure"' $?
}

testGetSyslogModuleVariables() {
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
    if "${PROZZIE_PREFIX}"/bin/prozzie config --describe wrongModule; then
        ${_FAIL_} '"prozzie config --describe wrongModule must show error"'
    fi
}

testDescribeMustShowHelpIfModuleIsNotPresent() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --describe; then
        ${_FAIL_} '"prozzie config --describe must show help with failure"' 
    fi
}

testDescribeMustShowAnErrorIfModuleDoesNotExist() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --describe wrongModule; then
        ${_FAIL_} '"prozzie config --describe wrongModule must show error"'
    fi
}

testSetupMustShowHelpIfModuleIsNotPresent() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config --setup; then
        ${_FAIL_} '"prozzie config --setup must show help with failure"' 
    fi
}

testConfigMustShowErrorIfModuleIsNotExist() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config wrongModule; then
        ${_FAIL_} '"prozzie config wrongModule must show error"'
    fi
}

testConfigMustShowHelpIfTryToSetMqttAndSyslogModules() {
    if "${PROZZIE_PREFIX}"/bin/prozzie config mqtt kafka.topic myTopic; then
        ${_FAIL_} '"prozzie config mqtt kafka.topic myTopic must show help"' 
    fi
    if "${PROZZIE_PREFIX}"/bin/prozzie config syslog kafka.topic myTopic; then
        ${_FAIL_} '"prozzie config syslog kafka.topic myTopic must show help"' 
    fi
}

testSetupCancellation() {
    ENV_BACKUP=$(<"${PROZZIE_CLI_ETC}"/.env)

    expect -c \
         "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s base
         expect \"Data HTTPS endpoint URL (use http://.. for plain HTTP): \"
         send \"\025blah.blah.blah\r\"
         expect \"Interface IP address : \"
         send \"\025blah.blah.blah.blah\r\"
         expect \"Client API key : \"
         send \"\025blahblahblah\r\"
         expect eof
         " >/dev/null 2>&1

    md5UselessENVFile=`md5sum "${PROZZIE_PREFIX}"/etc/prozzie/.env|awk '{ print $1 }'`

    expect -c \
         "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s base
         expect \"Data HTTPS endpoint URL (use http://.. for plain HTTP): \"
         send \"\025https://my.test.endpoint\r\"
         expect \"Interface IP address : \"
         send \"\025${INTERFACE_IP}\r\"
         expect \"Client API key : \"
         send \"\x03\"
         expect eof
         " >/dev/null 2>&1

    md5NewENVFile=`md5sum "${PROZZIE_PREFIX}"/etc/prozzie/.env|awk '{ print $1 }'`
    comp_res=`echo $md5UselessENVFile $md5NewENVFile|awk '{ print ($1==$2) ? 0 : 1 }'`

    ${_ASSERT_TRUE_} "\".ENV file mustn\'t be modified\"" '"$comp_res"'

    expect -c \
         "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -s base
         expect \"Data HTTPS endpoint URL (use http://.. for plain HTTP): \"
         send \"\025https://my.test.endpoint\r\"
         expect \"Interface IP address : \"
         send \"\025${INTERFACE_IP}\r\"
         expect \"Client API key : \"
         send \"\025mySuperApiKey\r\"
         expect eof
         " >/dev/null 2>&1

     md5NewENVFile=`md5sum "${PROZZIE_PREFIX}"/etc/prozzie/.env|awk '{ print $1 }'`
     comp_res=`echo $md5UselessENVFile $md5NewENVFile|awk '{ print ($1!=$2) ? 0 : 1 }'`

    ${_ASSERT_TRUE_} "\".ENV file must be modified\"" '"$comp_res"'

    echo "${ENV_BACKUP}" > "${PROZZIE_CLI_ETC}"/.env
}

#--------------------------------------------------------
# TEST WIZARD
#--------------------------------------------------------

testWizard() {
    ENV_BACKUP=$(<"${PROZZIE_CLI_ETC}"/.env)

    expect -c \
         "
         spawn "${PROZZIE_PREFIX}"/bin/prozzie config -w
         expect \"Do you want to configure modules? (Enter for quit): \"
         send \"f2k\r\"
         expect \"In what port do you want to listen for netflow traffic? :\"
         send \"\0255523\r\"
         expect \"JSON object of NF probes (It's recommend to use env var) :\"
         send \"\025{}\r\"
         expect \"Topic to produce netflow traffic? :\"
         send \"\025wizardFlow\r\"
         expect \"Do you want to configure modules? (Enter for quit): \"
         send \"\r\"
         expect eof
         " >/dev/null 2>&1

    genericTestModule 3 f2k 'NETFLOW_COLLECTOR_PORT=5523' \
                            'NETFLOW_KAFKA_TOPIC=wizardFlow' \
                            'NETFLOW_PROBES={}'

    echo "${ENV_BACKUP}" > "${PROZZIE_CLI_ETC}"/.env
}

. test_run.sh
