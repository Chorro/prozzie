---
---

# Prozzie installation

## Base linux installation

### Getting installation script
#### Automagical installation

Prozzie will be downloaded & installed if you execute the next command in a
linux terminal:

```bash
bash <(curl -L \
	--header "Authorization: token 4ea54f05cd7111c2e886f2c26f59b99109245053" \
	--header 'Accept: application/vnd.github.v3.raw' \
	'https://api.github.com/repos/wizzie-io/prozzie/contents/setups/linux_setup.sh?ref=0.4.0-pre1')
```

#### Installation from github repository

Clone the repo and execute the `setups/linux_setup.sh` script that will guide
you through the entire installation:

### Installation steps

You will be asked for a prozzie installation path, and you must remember it at
every change you want to make from now on.

If you have not installed docker or docker-compose yet, `linux_setup.sh` script
will install them and a few tools that it needs for installation, like `curl`.

You will be asked for the variables on `linux` section of
[VARIABLES.md](https://github.com/wizzie-io/prozzie/blob/master/VARIABLES.md).
The long description of these are:

INTERFACE_IP
: Interface IP to expose kafka (advertised hostname).

CLIENT_API_KEY
: Client API key you request to Wizz-in

ZZ_HTTP_ENDPOINT
: You WDP endpoint

After installation, you can
start and stop the prozzie using `bin/start-prozzie.sh` and
`bin/stop-prozzie.sh` under that installation path.

## Prozzie operation

Since all prozzie is contained in a docker compose, you can use
`docker-compose start` and `docker-compose stop` in the prozzie folder to start
and stop the prozzie and `docker-compose down` for delete all created
containers.

## Protocol installation

Please navigate through the left navigation bar to know how to set up and start
sending data using your desired protocol.

You can see the components installed in the next picture, so you can identify
the method to use to configure each one:

![Prozzie Components Diagram]({{ "/assets/img/prozzie_components_diagram.svg" | absolute_url }})
