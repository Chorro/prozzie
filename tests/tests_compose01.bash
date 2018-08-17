#!/usr/bin/env bash

testProzzieComposeCommand () {
    # prozzie compose version must show docker-compose version
    "${PROZZIE_PREFIX}/bin/prozzie" compose version --short >/dev/null 2>&1
}

. test_run.sh
