---
---

# SNMP prozzie support
## SNMP polling
In order to setup SNMP polling in prozzie, is advisable to add all snmp agents
to `SENSORS_ARRAY` environment variable before use monitor setup, using
the format described in
[monitor readme](https://github.com/wizzie-io/monitor#simple-snmp-monitoring).
For example, executing monitor setup this way:

```
MONITOR_SENSORS_ARRAY='{"sensor_id":1,"timeout":2000,"sensor_name": "my-sensor","sensor_ip": "172.18.0.1","snmp_version":"2c","community" : "public","monitors": [{"name": "mem_total", "oid": "HOST-RESOURCES-MIB::hrMemorySize.0", "unit": "%"}]}' setups/monitor_setup.sh
```

## SNMP traps
To listen for snmp in a specific port you have to use the `TRAPS_PORT` environment variable. This variable is defined in docker-compose yaml file with port number `162` by default.

You can check that messages are properly delivered using `prozzie kafka consume <your-monitor-topic>`.

## Custom mibs
Monitor connector includes all
[net-snmp mibs](http://www.net-snmp.org/docs/mibs/) distributed Mibs. Create a
docker named volume with the mibs you want to use and set it in
`MONITOR_CUSTOM_MIB_PATH` variable to to use your customs MIBs.

## Variables

REQUESTS_TIMEOUT
: Seconds between monitor polling. By default `25`

KAFKA_TOPIC
: Topic to produce monitor metrics. By default `monitor`

MONITOR_CUSTOM_MIB_PATH
: Monitor custom MIB volume. By default `monitor_custom_mibs`

SENSORS_ARRAY
: Monitor agents array. By default `''`
