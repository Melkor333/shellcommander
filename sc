#!/usr/bin/env bash

#shopt -u "strict:all" 2>/dev/null || true
set -e
SC_PATH="${SC_PATH:=$HOME/.local/share/shellcommander/shells}"
SC_TEMPLATE="shell.XXXX"

help() {
    echo TODO
    echo "start by running '$0 init'"
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
    local _PID="$5"
    shift 5;
    $@ <"$INPUT" >"$OUTPUT" 2>"$STDERR" &
    pid=$!
    echo "$pid" > $_PID
    wait "$pid"
    echo $? > "$EXIT"
    rm "$INPUT" || true # We don't care if we can't delete it
}

# Run a - usually shell - in the background
start() {
    SHELL_DIR=$(mktemp -d "${SC_PATH}/${SC_TEMPLATE}")
    # store command
    echo "$@" > "${SHELL_DIR}/shell_command"
    echo "$SHELL_DIR"
    [[ ! -p "${SHELL_DIR}/shell_input" ]] && mkfifo "${SHELL_DIR}/shell_input"
    # run command
    # We need to close the stdout file descriptor with >&-. Otherwise '(_interactive x y z) &' will never exit
    (_interactive "${SHELL_DIR}/shell_input" \
                 "${SHELL_DIR}/shell_output" \
                 "${SHELL_DIR}/shell_err" \
                 "${SHELL_DIR}/shell_exit" \
                 "${SHELL_DIR}/shell_pid" \
                 "$@") >&- &
    # TODO wait until pidfile exists or subshell died
}

# If sourced. This works only on bash but we don't care. We only test in bats :p
if ! (return 0 2>/dev/null); then
  if [[ -z "$1" ]]; then
     help
     exit 1
  fi
  if [[ "$1" == 'help' ]]; then
     help
     exit 0
  fi
  # Create the SC_PATH if it doesn't exist yet
  if ! [[ -d "$SC_PATH" ]]; then
      mkdir -p "$SC_PATH"
  fi

  $@
fi
