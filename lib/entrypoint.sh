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
    groupmod --gid "${USER_GID}" 'www-data' || true
    usermod --gid "${USER_GID}" --uid "${USER_ID}" 'www-data' || true

    apache2-foreground
}

entrypoint() {
    local url subject
    readonly subject="${1-}"

    # If the first argument is a command that exists, run it
    if [ -n "${subject}" ] && [ -n "$(command -v "${subject}" 2> /dev/null)" ]; then
        exec "${@}"
    else
        runSetup
        runChecks

        if [ -d /var/www/html/assets ]; then
            url="$(guessUrl)"
            readonly url

            printf "An assets folder has been found and is available at %s\nAvailable assets:\n%s\n%s\n\n" \
                "$(tput setaf 7)${url}/assets/$(tput sgr 0)" \
                "$(find /var/www/html/assets -maxdepth 1 -type d -exec echo -e "\t{}/" \; | sort)" \
                "$(find /var/www/html/assets -maxdepth 1 -type f -exec echo -e "\t{}" \; | sort)"
            fi

        defaultCommand "${@}"
    fi
}

guessUrl(){
    local hasHost isSetFromFile url

    hasHost="$(getent 'hosts' 'host.docker.internal' | awk '{ print $1 }')"
    isSetFromFile="$(grep 'docker.internal'  /etc/hosts | awk '{ print $1 }')"

    # host.docker.internal is not available on Linux, it is set in /etc/hosts
    # If `host.docker.internal` is available and not set in /etc/hosts,
    # we are in Docker Desktop for Mac or Windows.
    # If it is not available, or is available but set in /etc/hosts, we are on
    # Linux.

    if [ "${hasHost}" == 'host.docker.internal' ] && [ "${isSetFromFile}" != 'host.docker.internal' ]; then
        # we are on Docker Desktop for Mac or Windows
        url='Docker Desktop'
    else
        # we are on Linux
        url="https://$(tail -n1 /etc/hosts | cut -f1)"
        if [ ! -f '/var/www/www/api/data/generated.html' ]; then
            url="${url}/simplycode/"
        fi
    fi

    echo "${url}"
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

        url="$(guessUrl)"
        readonly url

        echo -e "Running on $(tput setaf 7)${url}$(tput sgr 0)\n"
    fi
}

runSetup() {
    if [ ! -f /var/www/html/index.html ]; then
        printf '%sFirst initialisation. Running setup...%s\n' \
            "$(tput setaf 7)$(tput setab 6)" \
            "$(tput sgr 0)"

        (
            PS4="$(echo -e "    ")"
            set -x
            ln -s /var/www/html/simplycode/js/ /var/www/html/js
            ln -s /var/www/www/api/data/generated.html /var/www/html/index.html
            ln -s /var/www/www/api/data/generated.html /var/www/html/index.js

            mkdir -p /var/www/html/simply/ \
                && ln -s /var/www/html/simplycode/simply/databind.js /var/www/html/simply/databind.js

            mv /var/www/lib/000-default.conf /etc/apache2/sites-available/000-default.conf
            mv /var/www/lib/403.php /var/www/html/403.php
            mv /var/www/lib/server.key /etc/ssl/private/ssl-cert-snakeoil.key
            mv /var/www/lib/server.pem /etc/ssl/certs/ssl-cert-snakeoil.pem
        )

        printf '%sSetup complete%s\n\n' \
            "$(tput setaf 7)$(tput setab 6)" \
            "$(tput sgr 0)"
    fi
}

entrypoint "$@"
