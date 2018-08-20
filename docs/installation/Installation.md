---
---

# Prozzie installation

## Base Linux installation

### Getting installation script
#### Automagical installation

Prozzie will be downloaded & installed if you execute the next command in a
linux terminal as root user or using sudo command:

```bash
sudo bash -c "$(curl -L --header 'Accept: application/vnd.github.v3.raw' 'https://api.github.com/repos/wizzie-io/prozzie/contents/setups/linux_setup.sh?ref=0.6.0')"
```

#### Installation from github repository

Clone the repo and execute the `setups/linux_setup.sh` script that will guide
you through the entire installation:

### Installation steps
#### Base prozzie installation

You will be asked for a prozzie installation path, and you must remember it at
every change you want to make from now on.

If you have not installed docker or docker-compose yet, `linux_setup.sh` script
will install them. Next tools it needs for installation:
- `curl`
- `net-tools`

You will be asked for the variables on `Linux` section of
[VARIABLES.md](https://github.com/wizzie-io/prozzie/blob/master/VARIABLES.md).
The long description of these are:

INTERFACE_IP
: Interface IP to expose kafka (advertised hostname).

CLIENT_API_KEY
: Client API key you request to Wizz-in

ZZ_HTTP_ENDPOINT
: You WDP endpoint

#### Modules configuration
After that, you can configure different prozzie connectors introducing the name or
the number in the prompted menu:

```bash
1) f2k
2) http2k
3) monitor
4) mqtt
5) sfacctd
6) syslog
Do you want to configure modules? (Enter for quit)
```

You can omit the prompt with `CONFIG_APPS` environment variable. For instance,
to configure only monitor and f2k, you can use `CONFIG_APPS='monitor f2k'`, and
you will directly be asked for these related apps. Similarly, you can omit the
whole prompt if that variable is empty, i.e., `CONFIG_APPS=''`.

If you ever want to reconfigure a specified protocol, you can run the
`prozzie config wizard` command.

## Prozzie operation

You can start, stop, create or destroy prozzie compose with installed commands
`prozzie start`, `prozzie stop`, `prozzie up` and `prozzie down`, respectively.

To operate at low level on created compose, you can use
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

# Prozzie uninstall

Prozzie doesn't provide any mechanism to uninstall prozzie. If you want to uninstall prozzie you must do manually.

When you install prozzie first time you must specify a `prefix`, by default It's `/usr/local`. In this prefix, prozzie creates following directories:

- `${PREFIX}/share/prozzie`
: Contains files about prozzie cli and docker compose files.
- `${PREFIX}/bin`
: Contains the symbolic link to prozzie command.
- `${PREFIX}/etc/prozzie`
: Contains information about prozzie modules configuration.
- `${PREFIX}/var/prozzie/backup`
: Contains prozzie backup when upgrade prozzie.

To uninstall prozzie you must follow the next steps:

1. Do `prozzie down` to stop and delete all modules docker container. Keep in mind that prozzie will stop and won't send data to WDP platform.
2. Remove `${PREFIX}/share/prozzie` and `${PREFIX}/etc/prozzie` folders.
3. Remove symbolic link named `prozzie` in `${PREFIX}/bin` directory. If `bin` folder It isn't necessary, then you can delete it.
4. Remove `${PREFIX}/var/prozzie` folder and its content.
