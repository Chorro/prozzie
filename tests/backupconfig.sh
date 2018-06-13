#!/usr/bin/env bash

# If you source this file in your tests, it will backup & restore prozzie
# config in every individual test.

declare -r env_bak=$(mktemp)

setUp () {
    if [[ -f "${PROZZIE_PREFIX}/etc/prozzie/.env" ]]; then
        cp "${PROZZIE_PREFIX}/etc/prozzie/.env" "$env_bak"
    fi
}

tearDown () {
    cp "$env_bak" "${PROZZIE_PREFIX}/etc/prozzie/.env"
    "${PROZZIE_PREFIX}/bin/prozzie" up -d
}
