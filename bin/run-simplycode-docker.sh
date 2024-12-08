#!/usr/bin/env bash

set -o errexit  # Exit script when a command exits with non-zero status.
set -o errtrace # Exit on error inside any functions or sub-shells.
set -o nounset  # Exit script on use of an undefined variable.
set -o pipefail # Return exit status of the last command in the pipe that exited with a non-zero exit code

: "${DOCKER:=docker}"

# ==============================================================================
# Exit codes
# ------------------------------------------------------------------------------
: readonly -i "${EXIT_OK:=0}"
: readonly -i "${EXIT_NOT_ENOUGH_PARAMETERS:=65}"
: readonly -i "${EXIT_INVALID_PARAMETER:=66}"
: readonly -i "${EXIT_COULD_NOT_FIND_DIRECTORY:=75}"
: readonly -i "${EXIT_NOT_CORRECT_TYPE:=81}"

# ------------------------------------------------------------------------------
# Foreground colors
# ------------------------------------------------------------------------------
: readonly "${COLOR_BLUE:=$(tput setaf 4)}"
: readonly "${COLOR_GREEN:=$(tput setaf 2)}"
: readonly "${COLOR_RED:=$(tput setaf 1)}"
: readonly "${COLOR_WHITE:=$(tput setaf 7)}"
# ------------------------------------------------------------------------------
: readonly "${RESET_TEXT:=$(tput sgr0)}"      # turn off all attributes
# ==============================================================================


# ==============================================================================
## Run the SimplyCode Docker container
# ------------------------------------------------------------------------------
## \nUsage: $0 [-dh][-i <docker-image>] <project-path>
##
## Where:
##         <docker-image> is an alternative Docker image to use
##         <project-path> is the path to the SimplyCode project to run
##
## Options:
##         -d|--dry-run                     Show the command that would be run without executing it
##         -h|--help                        Print this help dialogue and exit
##         -i|--docker-image=<docker-image> Use the specified Docker image
##
## Any additional arguments will be passed to the `docker run` command.
##
## For example:
##
##         $0 <project-path> /bin/bash
##
## The Docker executable can be overridden by setting the DOCKER environmental
## variable before calling this script:
##
##         DOCKER=/usr/local/docker $0 <project-path>
##
## The SimplyCode Docker container will be run with the given project path mounted
## to the container's /var/www/www/api/data directory. If the project has an assets
## directory, this will be mounted to /var/www/html/assets.
# ==============================================================================
usage() {
    local sScript sUsage

    sScript="$(basename "$0")"
    sUsage="$(grep '^##' < "$0" | cut -c4-)"

    echo -e "${sUsage//\$0/${sScript}}"
}

error(){
    message "ERROR" "${COLOR_RED}" "${@}" >&2
}

info(){
    message "INFO" "${COLOR_BLUE}" "${@}"
}

message(){
    local sType="${1?Three parameters required: <type> <color> <message>}"
    local sColor="${2?Three parameters required: <type> <color> <message>}"
    local sMessage="${3?Three parameters required: <type> <color> <message>}"

    echo -e "${COLOR_WHITE}[${sColor}${sType}${COLOR_WHITE}]${RESET_TEXT} ${sMessage}"

    # Each additional parameter will be treated as extra information to display with the error
    if [[ "$#" -gt 3 ]]; then
        shift 3
        for sMessage in "$@"; do
            echo -e "        ${sMessage}"
        done
    fi
}

run_simplycode_docker() {
    dryRun() {
        local sResult

        DOCKER='echo'
        sResult=$(executeCommand "${@}")

        iLines=$(echo "${sResult}" | sed -E 's/ --/\n--/g' | wc -l)
        sResult="$(echo -n "${sResult}" | sed -E 's/ --/ \\\n    --/g' | sed -n "1,${iLines}p")"

        echo -en "docker "
        echo -n "${sResult}" | head -n -1
        echo -n "${sResult}" | tail -n 1 | cut -d ' ' -f 5-6 | sed -E 's/$/ \\/g' | sed 's/^/    /'
        echo -n "${sResult}" | tail -n 1 | cut -d ' ' -f 7- | sed -E 's/ / \\\n/g' | sed 's/^/    /'
    }

    executeCommand() {
        local sDockerImage sProjectPath

        readonly sDockerImage="${1?Two parameters required: <docker-image> <project-path>}"
        shift
        readonly sProjectPath="${1?Two parameters required: <docker-image> <project-path>}"
        shift

        # ======================================================================
        # Build the run command
        # ----------------------------------------------------------------------
        local -a aCommand=("${DOCKER}" 'run')

        aCommand+=(
            '--env' "USER_GID=$(id -g)"
            '--env' "USER_ID=$(id -u)"
            '--interactive'
            '--network=default'
            '--publish' '80:80'
            '--publish' '443:443'
            '--rm'
            '--tty'
            '--volume' "${sProjectPath}:/var/www/www/api/data"
        )

        if [[ -d "${sProjectPath}/assets" ]]; then
            aCommand+=(
                '--volume' "${sProjectPath}/assets:/var/www/html/assets"
            )
        fi

        aCommand+=(
            "${sDockerImage}"
            "${@}"
        )

        # @TODO: Split command creation and execution into separate functions
        #        so dry-run can be simplified

        "${aCommand[@]}"
    }

    local -a aParameters
    local sArgument sDockerImage
    local bDryRun=false

    aParameters=()

    sDockerImage='ghcr.io/simplyedit/simplycode-docker:main'

    while (( "$#" )); do
        sArgument="${1}"
        shift
        case "${sArgument}" in
            -d | --dry-run)
                bDryRun=true
                ;;

            -\? | -h | --help)
                usage
                exit "${EXIT_OK}"
                ;;

            -i | --docker-image | --docker-image=?*)
                # If the parameter contains a `=` the path is part of the param, so we need to split it to get the value
                if grep '=' <(echo "${sArgument}");then
                    sDockerImage="${sArgument#*=}"
                else
                    # Else, the next param is the value, unless no param is provided
                    if [[ -n "${1:-}" && ! "${1}" =~ ^- ]]; then
                        sDockerImage="${1}"
                        shift
                    else
                        error "No value provided for ${sDockerImage}" "Call with --help for more information."
                        exit "${EXIT_NOT_ENOUGH_PARAMETERS}"
                    fi
                fi
                ;;

            --*|-*)
                error "Invalid option '${sArgument}'" "Call with --help for more information."
                exit "${EXIT_INVALID_PARAMETER}"
            ;;

            *)
                aParameters+=("${sArgument}")
                ;;
        esac
    done

    if [[ "${#aParameters[@]}" -lt 1 ]]; then
        error "One parameter required: <project-path>" "Call with --help for more information."
        exit "${EXIT_NOT_ENOUGH_PARAMETERS}"
    fi

    local sProjectPath="${aParameters[0]}"
    sProjectPath="$(realpath "${sProjectPath}")"
    aParameters=( "${aParameters[@]:1}" )

    if [[ ! -e "${sProjectPath}" ]];then
        error "Could not find directory: ${sProjectPath}"
        exit "${EXIT_COULD_NOT_FIND_DIRECTORY}"
    elif [[ ! -d "${sProjectPath}" ]];then
        error "Provided path is not a directory: ${sProjectPath}"
        exit "${EXIT_NOT_CORRECT_TYPE}"
    fi

    if [[ "${bDryRun}" == true ]]; then
        info "Dry run enabled. The following command would be run:\n"
        dryRun  "${sDockerImage}" "${sProjectPath}" "${aParameters[@]}"
        echo ""
    else
        executeCommand "${sDockerImage}" "${sProjectPath}" "${aParameters[@]}"
    fi
}

if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    export -f run_simplycode_docker
else
    run_simplycode_docker "${@}"
fi

#EOF
