---
---

# Syslog

To configure Syslog you can use `kcli` tool.

* syslog.properties

```
name=syslog
connector.class=com.github.jcustenborder.kafka.connect.syslog.UDPSyslogSourceConnector
tasks.max=1
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=false

#Settings
kafka.topic=syslog
syslog.host=0.0.0.0
syslog.port=1514
syslog.structured.data=true
```

You need to configure the syslog.properties file with your properties:

connector.class
: You can configure the connector class to use UDP, TCP or SSL

kafka.topic
: The Kafka topic to send the messages.

When you configure the `syslog.properties` you need to create the connector:

`kcli create syslog-connector < syslog.properties`

## Warning
Currently, the only port in what you can expose syslog server is 1514.
