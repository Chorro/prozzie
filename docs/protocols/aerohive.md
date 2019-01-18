---
---

# Aerohive

Prozzie has capability to listen [Aerohive Webhooks](https://developer.aerohive.com/docs/webhooks) to send received data to kafka. These are possible thanks to [Kafka Connect Aerohive Connector](https://github.com/wizzie-io/kafka-connect-aerohive).

## Requirements

To use aerohive client you need a trusted HTTP server, Prozzie can't provide you an HTTPS server, so you need an API-Gateway or reverse-proxy to forward HTTPS petitions to Aerohive client port.

You could use [Traefik](https://traefik.io/) or [Kong](https://konghq.com/) for this purpose and [Let's Encrypt](https://letsencrypt.org/) certificate authority. Next, you can see an example of how Aerohive connector works with Traefik:

![Aerohoive Diagram]({{ "assets/img/aerohive/aerohive-diagram.png" | absolute_url }})

1. You need configure in your HiveManager a Webhook with a `POST Url` and `Access Token`.
2. In `traefik` you need configure `Let's Encrypt` certificate and forward petitions to `/v1/data/*` endpoint.
3. You must provide to `Aerohive Connetor` the `Access Token` to verify the petitions.
4. You will receive your data If everything is right in your kafka's topic.

## Interactive script

You can run `prozzie config setup aerohive` to interactively configure one aerohive connector. You will be asked for the next variables, that can't have any default:

aerohive__access_token
: Access token to validate webhook callbacks

However, there are some others "hidden" variables that configure the connector.
They will be output at the end of the interactive setup, and you can reuse them
following the [Advanced configuration](#Advanced-configuration).

## Advanced configuration

To configure Aerohive you can use `kcli` tool.

`aerohive.properties file`

```properties
# Connector's Name
name=aerohive
# Connector's Class
connector.class=io.wizzie.kafka.connect.aerohive.WebhookSourceConnector
# Max number of tasks (only 1 allowed)
tasks.max=1
# Key converter to kafka
key.converter=org.apache.kafka.connect.storage.StringConverter
# Value converter to kafka
value.converter=org.apache.kafka.connect.storage.StringConverter

# Connector's client ID
aerohive.client_id=aerohive-webhook
# Aerohive Webhook token to verified requested data
aerohive.access_token=aerohive_secret_access_token
# Message processor
message_processor_class=io.wizzie.kafka.connect.aerohive.processor.StringProcessor
```

You need to configure a `aerohive.properties` file with your property:

aerohive.access_token
: Access token to validate webhook callbacks

When you configure the `aerohive.properties` file you need to create the connector:

`prozzie kcli create aerohive-connector < aerohive.properties`

You can check that messages are properly delivered using `prozzie kafka consume <your-aerohive-topic>`
