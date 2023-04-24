#!/usr/bin/env bash

#shopt -u "strict:all" 2>/dev/null || true
set -e

SC_PATH="${SC_PATH:=$HOME/.local/share/shellcommander/shells}"
if [[ -z "$SC_DIR" ]]; then
    # Random number is an ugly hack
    # Otherwise ISO Date is the best date! (timezone is a bit unnecessary in that case though)
    SC_DIR="$(date +"%Y-%m-%dT%H:%M:%S%:z")_$RANDOM"
fi

USAGE="$0 ACTION [FLAGS] [COMMAND]

ACTIONS:
  start COMMAND             Start a new shell in the background. COMMAND is the shell command you want to run

  list [-a]                 List open shells. with -a: List all existing shell folders

  command SHELL_DIR COMMAND Run a [possibly shell altering] command in a shell.
                            The COMMAND will be stored to the shell_command and output goes to shell_output

    SHELL_DIR               The full path of the shell directory
    COMMAND                 The command to run in this subshell

  close SHELL_DIR           Close an open shell (send 'exit' to this shell)
"

help() {
    echo "$USAGE"
}

# Trap functions

_clean_exit() {
    kill "$pid"
    # TODO: Maybe something like this, but properly capture the exitcodes
    #timeout 5 wait "$pid"
    #kill -9 "$pid"
    echo $? > "$EXIT"
    rm "$INPUT" || true # We don't care if we can't delete it
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
    # Sadly forces us to use bash4
    mypid=$BASHPID
    # Start traps for communication
    trap _clean_exit EXIT
    exec 20>"$OUTPUT" 21>"$STDERR"
    $@ <"$INPUT" >&20 2>&21 &
    pid=$!
    echo "$mypid" > "$_PID"
    wait "$pid"
    echo $? > "$EXIT"
    rm "$INPUT" || true # We don't care if we can't delete it
    trap - EXIT
}

# Run - usually a shell - in the background
start() {
    local shell_dir
    # TODO: parse $1 to catch impossible characters, trim paths, etc.
    shell_dir="${SC_PATH}/${SC_DIR}"
    mkdir -p "$shell_dir"
    # store command
    echo "$@" > "${shell_dir}/shell_command"
    echo "$shell_dir"
    [[ ! -p "${shell_dir}/shell_input" ]] && mkfifo "${shell_dir}/shell_input"
    # run command
    # We need to close the stdout file descriptor with >&-. Otherwise '(_interactive x y z) &' will never exit
    (_interactive "${shell_dir}/shell_input" \
                 "${shell_dir}/shell_output" \
                 "${shell_dir}/shell_err" \
                 "${shell_dir}/shell_exit" \
                 "${shell_dir}/shell_pid" \
                 "$@") >&- &
    # TODO wait until pidfile exists or subshell died
}

# Run a command in a shell
_command() {
    local shell_dir="$1"
    shift
    echo "$@" >> "$shell_dir/shell_command"
    _send_to_fifo "$shell_dir/shell_input" "$@"
}

close() {
    local shell_dir="$1" pid
    pid=$(cat "$shell_dir/shell_pid")
    _send_to_fifo "$shell_dir/shell_input" exit
    # Wait for the process to die or kill it.
    # Hacky workaround for things not accepting 'exit'
    # Also makes sure we only exit after $pid has finished
    if ! timeout 5s tail --pid=$pid -f /dev/null; then
       kill "$pid"
       if ! timeout 5s tail --pid=$pid -f /dev/null; then
           kill -9 "$pid"
       fi
    fi
    # TODO: If the process doesn't exist based on that, kill it with kill, kill -9, etc.
}

list() {
    local all=0
    while getopts "a" arg; do
        case $arg in
            a)
               all=1
                ;;
        esac
    done
    for dir in "$SC_PATH"/*; do
        if [[ "$all" -eq 1 ]] || [[ -p "${dir}/shell_input" ]]; then
            echo "$dir"
        fi
    done
}
# ls is an alias of list :)
ls() { list $@; }

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
    if [[ "$1" == 'command' ]]; then
        shift
        # command is a reserved word :)
        _command "$@"
    else
        $@
    fi
fi
