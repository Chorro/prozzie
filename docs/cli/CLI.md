---
---

# Prozzie Command Line Interface

## Description
Prozzie is the main entry point of Wizzie Data Plane (WDP) platform.

Prozzie CLI allows the user (or admin) operate prozzie with no need to know
internals or advance docker or docker-compose commands.

## Synopsis
`prozzie [-h|--help] <command> [<command args>]`

## Options
`-h|--help`
: Shows prozzie CLI help

## Commands

### Prozzie service operation

You have the next commands for basic prozzie operation:

`prozzie compose`
: Send generic commands to prozzie docker compose

`prozzie down`
: Stop prozzie services and remove kafka queue

`prozzie start`
: Start prozzie services

`prozzie stop`
: Stop prozzie services

`prozzie up`
: (re)Create and start prozzie services


You can start, stop, create or destroy prozzie compose with installed commands
`prozzie start`, `prozzie stop`, `prozzie up` and `prozzie down`, respectively.

The difference between `up`/`down` and `start`/`stop` is that the former will
create or destroy containers and associated data, but the latter will only start
or stop them if they are already created with former commands.

To operate at low level on created compose, you can use `prozzie compose`
command, and it will forward arguments with proper compose
file and configurations.

So, `prozzie start`, `prozzie stop`, `prozzie up` and
`prozzie down` are just shortcuts for the long version
`prozzie compose [up|down|...]`, and arguments will be also forwarded.

### Prozzie message queue operation
#### Topic management
You can manage topics with `prozzie kafka topics` subcommand. If you execute 
it, you can check the options it offers to you. Check included examples in
this document.

##### Creating topics
```bash
prozzie kafka topics --create --topic abc --partitions 1 --replication-factor 1
```

Note that you don't need to create a topic before produce data. Kafka cluster
creates it for you at the same moment you produce the first message.

#### List topics
```bash
prozzie kafka topics --list
```

#### Produce messages
```bash
prozzie kafka produce <topic>
```

You can introduce as many messages as you want, separated by a newline.

#### Advanced operation
If you know how to use kafka distributed configuration scripts, you can
execute them directly using
`prozzie compose exec kafka /opt/kafka/bin/<you_script>`.

## Creating custom subcommands

You can create your own prozzie CLI subcommands just placing it under
`<installation dir>/share/prozzie/cli/prozzie-<cmd>.bash`. For example, `foo`
subcommand would be `<installation dir>/share/prozzie/cli/prozzie-foo.bash`.
This new CLI command has to provide a short guide of what does it do via
`--shorthelp`, in order to be shown in `prozzie` help. Also, it will be provided
with prozzie installation prefix with `PREFIX` environment variable.

Beyond that, each prozzie CLI subcommand must provide treatment for it's
subcommands, help, and any action it wants to perform.
