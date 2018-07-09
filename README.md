<p align="center">
    <img src="docs/assets/img/prozzie.logo.svg" alt="Prozzie" title="Prozzie" width="250%"/>
</p>

[![wizzie-io](https://img.shields.io/badge/powered%20by-wizzie.io-F68D2E.svg)](https://github.com/wizzie-io/)
[![CircleCI](https://circleci.com/gh/wizzie-io/prozzie/tree/master.svg?style=shield&circle-token=0f81b1424c32aa36f1e327701a0cd84dbc0f102b)](https://circleci.com/gh/wizzie-io/prozzie/tree/master) 
[![Docs](https://img.shields.io/badge/docs-current-brightgreen.svg)](https://wizzie-io.github.io/prozzie/) 
[![GitHub release](https://img.shields.io/github/release/wizzie-io/prozzie.svg)](https://github.com/wizzie-io/prozzie/releases/latest) 
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

> Main entry point for the data plane of [Wizzie Data Platform](http://wizzie.io/).

Under the hoods, prozzie is just a docker-compose file that provides you the
basics for sending the data events to WDP: authentication, encryption,
homogenization and a flexible kafka buffer for back-pressure and local data
persistence.

It provides out-of-the-box support for **json** over kafka, http POSTs, and
mqtt, and it supports others such netflow, snmp and json over mqtt with a small
configuration. Please see [Supported Protocols](#Supported-Protocols) for a more
exhaustive list.

## Basic usage
### Sending data

You can send raw data using curl or kafka protocol, and prozzie will manage to
send the data to WDP. After that, you will be able to see it in the analytic
platform.

Here you can send data using curl:

```bash
$ curl -d '{"test":1,"timestamp":1518086046}' \
localhost:7980/v1/data/testtopic
```

You can batch JSONs and prozzie will split:

```bash
$ curl -d \
'{"test":1,"timestamp":1518086046}{"test":1,"timestamp":1518086047}' \
localhost:7980/v1/data/testtopic
```

And using a kafka producer (for example, prozzie built in one):

```bash
$ prozzie kafka produce testtopic
```

You can check that prozzie kafka receives message:

```bash
$ prozzie kafka consume testtopic
```

And check the result on WDP. (Note: as a simpler alternative to WDP, we use an
example echo server that will receive JSON messages in the demo).

[![asciicast](https://asciinema.org/a/ofgYDhbA5BG29FQRxFYAuDVYy.png)](https://asciinema.org/a/ofgYDhbA5BG29FQRxFYAuDVYy)

### Installation

Clone the repo and execute the `setups/linux_setup.sh` script that will guide
you through the entire installation. You can also use the next command if you
don't want to waste your time messing with git:

```bash
bash <(curl -L \
	--header 'Accept: application/vnd.github.v3.raw' \
	'https://api.github.com/repos/wizzie-io/prozzie/contents/setups/linux_setup.sh?ref=0.5.0')
```

You will be asked for a prozzie installation path. After installation, you can
start and stop the prozzie using `bin/start-prozzie.sh` and
`bin/stop-prozzie.sh` under that installation path.

After that, you will be prompted for the different protocols configurations
prozzie supports.

Since all prozzie is contained in a docker compose, you can use
`docker-compose start` and `docker-compose stop` in the prozzie folder to start
and stop the prozzie, and `docker-compose down` for delete all created
containers.

### Operation
After installation, you can use `prozzie config` command to (re)configure different prozzie components.

Syslog and mqtt protocols are handled via kafka connect, so you need to call
`prozzie kcli` component to handle them.

In order to operate on created compose, you can use `prozzie compose` command,
and it will forward arguments with proper compose file and configurations. You
can start, stop, create or destroy prozzie compose with shortcuts
`prozzie start`, `prozzie stop`, `prozzie up` and `prozzie down` shortcuts, and
arguments will be forwarded to these commands.

## Supported Protocols

- [x] Kafka
- [x] [JSON over HTTP](https://github.com/wizzie-io/n2kafka/blob/master/src/decoder/zz_http2k/README.md)
- [x] [Syslog: UDP, TCP, SSL](https://github.com/jcustenborder/kafka-connect-syslog)
- [x] [MQTT](https://github.com/wizzie-io/kafka-connect-mqtt.git) - [MQTT Setup](https://github.com/wizzie-io/prozzie/docs/MQTT.md)
- [x] [Flow](docs/flow.md) protocols,
      [Netflow](https://github.com/wizzie-io/f2k), sFlow (integrated via
      [pmacct](http://www.pmacct.net/)) and pmacct family.
- [x] [Meraki](docs/meraki.md)
- [x] [SNMP](docs/snmp.md)

## LICENSE
This project is licensed under the terms of the [Apache 2.0 license](LICENSE.md)
