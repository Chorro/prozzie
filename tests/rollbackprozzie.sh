#!/usr/bin/env bash

# If you source this file in your tests, it will restore prozzie
# version files in every individual test.

tearDown () {
    declare backup_file
    backup_file="$(ls "${PROZZIE_PREFIX}"/var/prozzie/backup/)"

    if [ -f "${PROZZIE_PREFIX}/var/prozzie/backup/$backup_file" ]; then
        tar -P -zxf "${PROZZIE_PREFIX}/var/prozzie/backup/$backup_file" -C /
        rm -rf "${PROZZIE_PREFIX}/var/prozzie/backup/*"
    fi
}
