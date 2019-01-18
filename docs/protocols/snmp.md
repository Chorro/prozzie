---
---

# SNMP prozzie support

## SNMP polling

In order to setup SNMP polling in prozzie, is advisable to add all snmp agents
to `SENSORS_ARRAY` environment variable before use monitor setup, using
the format described in
[monitor readme](https://github.com/wizzie-io/monitor#simple-snmp-monitoring).

For example:

```bash
MONITOR_SENSORS_ARRAY='{"sensor_id":1,"timeout":2000,"sensor_name": "my-sensor","sensor_ip": "172.18.0.1","snmp_version":"2c","community" : "public","monitors": [{"name": "mem_total", "oid": "HOST-RESOURCES-MIB::hrMemorySize.0", "unit": "%"}]}'
```

To configure SNMP you can use `prozzie config setup snmp`

## SNMP traps

To listen for snmp in a specific port you have to use the `TRAPS_PORT` environment variable. This variable is defined in docker-compose yaml file with port number `162` by default.

You can check that messages are properly delivered using `prozzie kafka consume <your-monitor-topic>`.

## Custom mibs

Monitor connector includes all
[net-snmp mibs](http://www.net-snmp.org/docs/mibs/) distributed MIBs. If you
want to add more, the easier way is to set the MONITOR_CUSTOM_MIB_PATH
variable. When you set it, the next things happens:

* If the path is a directory or a docker volume, all files under that are added to custom MIBs.
* If the path is a file, that file will be copied to custom mibs.
* If the variable is `monitor_custom_mibs`, nothing happens.
* Otherwise, you have an error.

Internally, all variables are added to `prozzie_monitor_custom_mibs` volume.
The procedure to delete old MIBs is to manually mount the volume in a temporary
container and delete it:

```bash
docker run --rm -it -v prozzie_monitor_custom_mibs:/mibs --workdir /mibs alpine sh
```

## Variables

REQUESTS_TIMEOUT
: Seconds between monitor polling. By default `25`

KAFKA_TOPIC
: Topic to produce monitor metrics. By default `monitor`

MONITOR_CUSTOM_MIB_PATH
: Monitor custom MIB volume. By default `monitor_custom_mibs`

SENSORS_ARRAY
: Monitor agents array. By default `''`
