---
---

# JSON/kafka
You can send JSON data over kafka using `prozzie kafka produce` command, and check proper reception with `prozzie kafka produce`.

Produce a valid JSON message is command user's responsibility; the command will not check that.

For more details please see the [CLI](../cli/CLI) documentation.

You can also send JSON data over kafka using in-prozzie embedded kafka producer
directly (or similar kafka client) to port 9092, and make sure to use the
previously exported IP address in prozzie installation to consume from kafka:

```bash
$ kafka-console-producer.sh --broker-list 192.168.1.203:9092 --topic testtopic
```

You can check that prozzie kafka receives the message with:

```bash
$ kafka-console-consumer.sh --bootstrap-server 192.168.1.203:9092 --topic testtopic
```

If you don't have them installed, you can run the kafka producer and consumer
integrated in prozzie with
`docker-compose exec kafka /opt/kafka/bin/kafka-console-{producer,consumer}.sh`

Since prozzie will convert all messages to kafka protocol, you can use the
previous command to check that prozzie is receiving them and how.
