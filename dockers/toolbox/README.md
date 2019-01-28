<p align="center">
    <img src="docs/assets/img/prozzie-toolbox.logo.png" alt="Prozzie Toobox" title="Prozzie Toolbox" width="75%"/>
</p>

[![wizzie-io](https://img.shields.io/badge/powered%20by-wizzie.io-F68D2E.svg)](https://github.com/wizzie-io/)
[![wizzie-io](https://img.shields.io/badge/%20-Docker-0DB7ED.svg?logo=docker)](https://hub.docker.com/r/wizzieio/prozzie-toolbox/)
[![](https://images.microbadger.com/badges/image/wizzieio/prozzie-toolbox.svg)](https://microbadger.com/images/wizzieio/prozzie-toolbox "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/wizzieio/prozzie-toolbox.svg)](https://microbadger.com/images/wizzieio/prozzie-toolbox "Get your own version badge on microbadger.com")

# Prozzie Toolbox

Prozzie Toolbox is a recopilation of tools to use in [Prozzie](https://github.com/wizzie-io/prozzie)

## How to use

To use `prozzie-toolbox` you can run next command:

```bash
docker run -it --rm wizzieio/prozzie-toolbox sh -c "echo 'Hello from prozzie-toolbox'"
```

If you want to use your own host, you must use `--net` docker option with `host` value.

## Tools

- [curl](https://curl.haxx.se/)
- [jq](https://stedolan.github.io/jq/)
- [rsync](https://rsync.samba.org/)
- [yaml2json](https://github.com/bronze1man/yaml2json)
- [shellcheck](https://github.com/koalaman/shellcheck)
