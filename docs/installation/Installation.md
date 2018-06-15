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
	'https://api.github.com/repos/wizzie-io/prozzie/contents/setups/linux_setup.sh?ref=0.5.0')
```

#### Installation from github repository

Clone the repo and execute the `setups/linux_setup.sh` script that will guide
you through the entire installation:

### Installation steps
#### Base prozzie installation

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

#### Modules configuration
After that, you can configure prozzie different apps introducing the name or
the number in the prompted menu:

```bash
1) f2k
2) monitor
3) sfacctd
Do you want to configure modules? (Enter for quit)
```

You can omit the prompt with `CONFIG_APPS` environment variable. For instance,
to configure only monitor and f2k, you can use `CONFIG_APPS='monitor f2k'`, and
you will directly be asked for these related apps. Similarly, you can omit the
whole prompt if that variable is empty, i.e., `CONFIG_APPS=''`.

If you ever want to reconfigure an specified protocol, you can launch the
individual script under `setup` folder directly.

## Prozzie operation

You can start, stop, create or destroy prozzie compose with installed commands
`prozzie start`, `prozzie stop`, `prozzie up` and `prozzie down`, respectively.

In order to operate at low level on created compose, you can use
`prozzie compose` command, and it will forward arguments with proper compose
file and configurations. So, `prozzie start`, `prozzie stop`, `prozzie up` and
`prozzie down` are just shortcuts for the long version
`prozzie compose [up|down|...]`, and arguments will be also forwarded.

## Protocol installation

Please navigate through the left navigation bar to know how to set up and start
sending data using your desired protocol.

You can see the components installed in the next picture, so you can identify
the method to use to configure each one:

![Prozzie Components Diagram]({{ "/assets/img/prozzie_components_diagram.svg" | absolute_url }})
