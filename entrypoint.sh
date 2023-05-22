#!/bin/bash

# errexit   Exit script when a command exits with non-zero status.
# errtrace  Exit on error inside any functions or sub-shells.
# nounset   Exit script on use of an undefined variable.
# pipefail  Return exit status of the last command in the pipe that exited with a non-zero exit code
set -o errexit -o errtrace -o nounset -o pipefail

checkEnv() {
    local fail=0

    if [ "${USER_ID-}" = '' ] || [ "${USER_GID-}" = '' ]; then
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
    local text

    if [ ! -d '/var/www/www/api/data' ]; then
        # shellcheck disable=SC2016
        printf '%sPlease call this docker image with --volume "${PWD}:/var/www/www/api/data"%s\n' \
            "$(tput setaf 7)$(tput setab 1)" \
            "$(tput sgr 0)" \
            >&2
        fail=1
    elif [ ! -f '/var/www/www/api/data/generated.html' ]; then
        text=$(cat <<EOF
%sThere does not seem to be a "generated.html" file.%s
If you have not yet saved your application, this is expected.
Otherwise, this might indicate a problem with the volume mount.
EOF
)
        # shellcheck disable=SC2059
        printf "${text}\n" \
            "$(tput setaf 3)" \
            "$(tput sgr 0)" \
            >&2
    fi

    return "${fail}"
}

defaultCommand() {
    groupmod --gid "${USER_GID}" 'www-data'
    usermod --gid "${USER_GID}" --uid "${USER_ID}" 'www-data'

    apache2-foreground
}

entrypoint() {
    local -r subject="${1-}"

    # If the first argument is a command that exists, run it
    if [ -n "${subject}" ] && [ -n "$(command -v "${subject}" 2> /dev/null)" ]; then
        exec "${@}"
    else
        runChecks
        defaultCommand "${@}"
    fi
}

runChecks() {
    local pass=true
    local url

    checkEnv || pass=false
    checkPaths || pass=false

    if [ "${pass}" = false ]; then
        exit 1
    else
        printf '%sAll checks passed%s\n\n' \
            "$(tput setaf 7)$(tput setab 2)" \
            "$(tput sgr 0)"

        echo "Contents of volume /var/www/www/api/data:"
        find /var/www/www/api/data -maxdepth 1 -type d -exec echo -e "\t{}/" \;
        find /var/www/www/api/data -maxdepth 1 -type f -exec echo -e "\t{}" \;

        url="https://$(tail -n1 /etc/hosts | cut -f1)"
        if [ ! -f '/var/www/www/api/data/generated.html' ]; then
            url="${url}/simplycode/"
        fi

        echo -e "Running on $(tput setaf 7)${url}$(tput sgr 0)\n"
    fi
}

entrypoint "$@"
