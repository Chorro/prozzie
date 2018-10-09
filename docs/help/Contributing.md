---
---

# Prozzie contributing guidelines

First of all, thanks for contribute to Wizzie prozzie! Here you will find
guidelines to add features or fix the project.

## I don't want to contribute, I just have a question to do
Please review the project [FAQs](FAQs) to check if your question already has
an answer. In another case, feel free to raise an issue with the label
`question`, and it will be answered ASAP.

## What should I know before I get started
Prozzie is composed of pieces, and it could happen that the changes you want
to do doesn't belong to prozzie but one of its components. In that case,
please try to identify the issue's right place to be.

For example, if you want a new feature or behavior in
[prozzie CLI](https://wizzie-io.github.io/prozzie/cli/CLI), you will probably
need to modify this repository. If you are going to support a new feature in
the
[supported protocols](https://github.com/wizzie-io/prozzie/#supported-protocols),
you probably need to address the issue to that protocol handler connector.

But if you know that the protocol handler connector does what you want to do,
and there is no way to achieve it with prozzie, then you need to address the
issue here.

## How can I test prozzie dirt-and-quickly
### Install "In a docker"
You can run a docker container that can control the host docker using this
command:

```bash
docker run -it -v /var/run/docker.sock:/var/run/docker.sock ubuntu:16.04
```

And then install prozzie using the install instructions, or a development
version if you mount the repository with `-v <prozzie_path>:/prozzie` and
execute `/prozzie/linux_setup.sh`. If you install it from curl, or want to
clone the repo, you will need to install `ca-certificates` before.

Be careful with that method because you can't autodetect public IP address that
way: The detected IP address will be that container's one, and kafka will be
unreachable. You need to use the host public IP manually.

Please note that this container is handling the host docker daemon, so you will
see the containers it creates using `docker ps` at the host. This is in no way
a safer way to test anything, and docker daemon will not purge prozzie
containers at this container's exit: you have to delete them manually at the
end (if you want).

### Testing a protocol: Using a test environment image
If you need to test one of the prozzie connectors individually, it may be
easier to use some of the prepared images. Do not trust in this images
stability: included tools will be added and deleted as a convenience, so if you
want to relay in them to your tests, please use your image.

The testing instruction will be analogous to the previous answer, but using
`wizzieio/prozzie-test-env:ubuntu-16.04` as the image.

## Adding an enhancement/feature

### ... in the prozzie docs
If you want to enhance docs, just change it and send a PR.

### ... in the prozzie cli
Check [cli README.md](cli/README.md), and [Add a test](Add-a-test)

### Add a connector
#### Docker-based
Check [compose README.md](compose/README.md), [cli README.md](cli/README.md)
and [Add a test](Add-a-test)

#### Kafka-connect based
Currently, you have to extend `gcr.io/wizzie-registry/wizzie-kc:0.1.0`
container. A more dynamic way to do it is on development.

### Add a test
Check [tests README.md](tests/README.md).
