---
---

# MQTT

## Interactive script

You can run `prozzie config setup mqtt` to interactively configure one mqtt kafka
connector. You will be asked for the next variables, that can't have any
default:

mqtt__server_uris
: MQTT brokers

mqtt__topic
: MQTT Topics to consume

kafka__topic
: Topic to produce MQTT consumed messages

However, there are some others "hidden" variables that configure connector.
They will be output at the end of interactive setup, and you can reuse them
following the [Advanced configuration](#Advanced-configuration).

## Advanced configuration

To configure MQTT you can use `kcli` tool.

* mqtt.properties

```properties
name=mqtt
connector.class=com.evokly.kafka.connect.mqtt.MqttSourceConnector
tasks.max=1
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.storage.StringConverter

#Settings
kafka.topic=mqtt
mqtt.client_id=my-id
mqtt.clean_session=true
mqtt.connection_timeout=30
mqtt.keep_alive_interval=60
mqtt.server_uris=tcp://localhost:1883
mqtt.topic=mqtttopic/1
mqtt.qos=1
message_processor_class=com.evokly.kafka.connect.mqtt.sample.StringProcessor
```

You need to configure a mqtt.properties file with your properties:

mqtt.server_uris
: The MQTT brokers.

mqtt.topic
: The MQTT topics to subcribe.

kafka.topic
: The Kafka topic to send the messages.

When you configure the `mqtt.properties` you need to create the connector:

`prozzie kcli create mqtt-connector < mqtt.properties`

You can check that messages are properly delivered using `prozzie kafka consume <your-mqtt-topic>`
