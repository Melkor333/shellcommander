#!/usr/bin/env bash

#shopt -u "strict:all" 2>/dev/null || true
set -e

SC_TEMPLATE="$HOME/.local/share/shellcommander/shells/shell.XXXX"

help() {
    echo TODO
    echo "start by running '$0 init'"
}

sc_count() {
    local SC_COUNT
    SC_COUNT=$(cat "${SC_PATH}/count")
    ((++SC_COUNT))
    echo "$SC_COUNT" | tee "${SC_PATH}/count"
}

# Define required variables
# TODO: Always executed if SC_INITIALIZED!=true or something the like
init() {
    if [[ -z "$1" ]]; then
        mkdir -p "${SC_TEMPLATE%/*}"
        declare -xg SC_PATH=$(mktemp -d "$SC_TEMPLATE")
    else
        declare -xg SC_PATH="$1"
    fi
    mkdir -p "$SC_PATH"
    echo 0 > "${SC_PATH}/count"
    printf 'declare -gx SC_PATH="%s"\n' "$SC_PATH"
}

# Abort if variable is empty/undefined
_require() {
    if [[ -z "${!1}" ]]; then
        echo "$1 is empty"
        return 1
    fi
}

# Send to a fifo
# Args:
# - fifo
# - command
_send_to_fifo() {
    # open for writing
    exec 20> $1
    shift;
    echo "$@" >&20

    # to close it
    exec 20>&-
}

# like detached but also with input redirection
# Args
# - input file (fifo will be created)
# - output file
# - stderr file
# - exit file where exit status will be written
# 'shell arguments'
# Returns nothing
_interactive() {
    # TODO: Maybe use 'https://github.com/subhav/web_shell/blob/master/command_server.sh'
    local INPUT="$1"
    local OUTPUT="$2"
    local STDERR="$3"
    local EXIT="$4"
    shift 4;
    # TODO: Fork away
    $@ <"$INPUT" >"$OUTPUT" 2>"$STDERR"
    echo $? > "$EXIT"
    rm "$INPUT" || true # We don't care if we can't delete it
}

# Run a - usually shell - in the background
start() {
    SC_COUNT=$(sc_count)
    # store command
    echo "$@" > "${SC_PATH}/${SC_COUNT}_command"
    [[ ! -p "${SC_PATH}/${SC_COUNT}_input" ]] && mkfifo "${SC_PATH}/${SC_COUNT}_input"
    # run command
    (_interactive "${SC_PATH}/${SC_COUNT}_input" \
                 "${SC_PATH}/${SC_COUNT}_output" \
                 "${SC_PATH}/${SC_COUNT}_err" \
                 "${SC_PATH}/${SC_COUNT}_exit" \
                 "$@") &
    echo $! > "${SC_PATH}/${SC_COUNT}_pid"
    exit
}

# If sourced. This works only on bash but we don't care. We only test in bats :p
if ! (return 0 2>/dev/null); then
  if [[ -z "$1" ]]; then
     help
     exit 1
  fi
  if [[ "$1" == 'init' ]]; then
     shift;
     init "$@"
     exit 0
  fi

  _require SC_PATH || { help; exit 1; }

  $@
fi
