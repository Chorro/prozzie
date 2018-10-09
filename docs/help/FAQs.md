---
---

# Prozzie FAQs

## How do I contribute to the project?
Please read [contributing](Contributing) section.

## How do I install prozzie in docker container
You can't, at least easily. Since prozzie is composed of dockers, you would
need to use some docker-in-docker skills to use it that way.

You can use a docker container with capabilities to manage host docker daemon,
and use it to install prozzie in. However, that configuration is not a
priority to maintain, so you can have a hard time using it. To do that, check
[How can I test prozzie](Contributing#How-can-I-test-prozzie-dirt-and-quickly).

## Troubleshooting: I don't see my messages in the kafka queue
### Kafka reachability
Make sure that the producer machine has access to whatever address have you set
in `INTERFACE_IP` variable. Check it with
`prozzie config get base INTERFACE_IP`

Due to the kafka broker discovery system, kafka client will make the first
attempt to connect to the configured broker (prozzie address in this case),
and them prozzie will say that all available brokers are `INTERFACE_IP`
variable. If the producer, being the prozzie or an external kafka one, is not
able to reach it, message production will fail.

For example, imagine that you use as `INTERFACE_IP` the hostname of the
prozzie, that is not resoluble by DNS. You can say to the kafka client the IP
address of the prozzie, it will connect OK the first time, the client will
receive the hostname as "next broker to connect", and then proper kafka
connection will not be possible.

So, contrary to others connection like HTTP, you need to be sure that both
directions are right from the producer view: The bootstrap and the returned
using `INTERFACE_IP`.

### Connector logs
Please review the logs of the connector using `prozzie logs <connector>`searching for possible errors.

### Connector reachability
You can execute commands in connector containers. Use
`prozzie compose exec sh`, install tcpdump, and check if packets are reaching
the connector interface.
