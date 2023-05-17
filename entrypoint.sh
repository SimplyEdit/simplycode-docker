#!/bin/bash

# errexit   Exit script when a command exits with non-zero status.
# errtrace  Exit on error inside any functions or sub-shells.
# nounset   Exit script on use of an undefined variable.
# pipefail  Return exit status of the last command in the pipe that exited with a non-zero exit code
set -o errexit -o errtrace -o nounset -o pipefail

checkEnv() {
    local fail=0

    if [ "${USER_ID:-}" = '' ] || [ "${USER_GID:-}" = '' ]; then
        # shellcheck disable=SC2016
        printf '%sPlease call this docker image with --env "USER_ID=$(id -u)" --env "USER_GID=$(id -g)"%s\n' \
            "$(tput setaf 7)$(tput setab 1)" \
            "$(tput sgr 0)" \
            >&2
        fail=1
    fi

    return "${fail}"
}

checkPaths() {
    local fail=0

    if [ ! -d '/var/www/www/api/data' ]; then
        # shellcheck disable=SC2016
        printf '%sPlease call this docker image with --volume "${PWD}:/var/www/www/api/data"%s\n' \
            "$(tput setaf 7)$(tput setab 1)" \
            "$(tput sgr 0)" \
            >&2
        fail=1
    fi

    return "${fail}"
}

defaultCommand() {
    groupmod --gid "${USER_GID}" 'www-data'
    usermod --gid "${USER_GID}" --uid "${USER_ID}" 'www-data'

    apache2-foreground
}

entrypoint() {
    local -r A="${1-}"

    if [ -n "${A}" ] && [ -n "$(command -v "${A}" 2> /dev/null)" ]; then
        exec "${@}"
    else
        runChecks
        defaultCommand "${@}"
    fi
}

runChecks() {
    local pass=true

    checkEnv || pass=false
    checkPaths || pass=false

    if [ "${pass}" = false ]; then
        exit 1
    fi
}

entrypoint "$@"