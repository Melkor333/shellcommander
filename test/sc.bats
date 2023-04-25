# Required for e.g. 'run --partial'
bats_require_minimum_version 1.5.0

setup() {
    set -eo pipefail
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/..:$PATH"
    # Set home, as used lateron
    export SC_PATH="${BATS_TEST_TMPDIR}"
}

teardown() {
  # this always fails because it gets the PID of the ps itself command aswell..
  # Otherwise it kills all subprocesses that might be lingering around
  # It somehow doesn't work when a test fails
  # Leaving it anyway for users testing without `unshare`
  kill $(ps -s $$ -o pid=) 2&>/dev/null || true
}

@test "Run Help" {
    run -0 sc help
    assert_output --partial "ACTION [FLAGS] [COMMAND]"

    # No params should also
    run -1 sc
    assert_output --partial "ACTION [FLAGS] [COMMAND]"
}

@test "Start a bash in the Background" {
    local bash_pid shell_path
    # Regarding the 3>&-, see
    # see https://bats-core.readthedocs.io/en/stable/writing-tests.html#file-descriptor-3-read-this-if-bats-hangs
    shell_path=$(sc start bash 3>&-)

    assert_file_exists "${shell_path}/shell_pid"
    # TODO parse rest of ISO time
    assert_regex "${shell_path##*/}" ".*$(date --iso-8601).*"
    bash_pid=( $(cat "${shell_path}/shell_pid") )
    # We check too fast for an existing command file :)

    # Command is stored
    assert_file_exists "${shell_path}/shell_command"
    assert_file_contains "${shell_path}/shell_command" 'bash'
    # Input exists
    assert_fifo_exists "${shell_path}/shell_input"

    # Output file gets created properly
    exec 20>"${shell_path}/shell_input"
    echo 'echo output_file' >&20
    assert_file_exists "${shell_path}/shell_output"
    assert_file_contains "${shell_path}/shell_output" 'output_file'
    echo "pid is: $bash_pid"
    ps
    assert ps -p $bash_pid > /dev/null
    # Exit
    echo 'exit' >&20

    # Command shouldn't exist
    refute ps -p $bash_pid > /dev/null # Sometimes that fails
    assert_file_exists "${shell_path}/shell_exit"
    assert_file_contains "${shell_path}/shell_exit" '0'
    assert_file_not_exists "${shell_path}/shell_input"
}

@test "Stop a shell" {
    local shell_path
    shell_path=$(sc start bash 3>&-)
    bash_pid=( $(cat "${shell_path}/shell_pid") )

    assert ps -p "$bash_pid" > /dev/null

    sc close "$shell_path"

    refute ps -p "$bash_pid" > /dev/null
}

@test "List all open shells" {
    local shell_path shell_path2 shell_path3
    shell_path=$(sc start bash 3>&-)
    shell_path2=$(sc start bash 3>&-)
    shell_path3=$(sc start bash 3>&-)
    sc close "$shell_path3"

    run -0 sc list
    assert_output --partial "$shell_path"
    assert_output --partial "$shell_path2"
    refute_output --partial "$shell_path3"
}

@test "List all shells, including closed" {
    local shell_path shell_path2 shell_path3
    shell_path=$(sc start bash 3>&-)
    shell_path2=$(sc start bash 3>&-)
    shell_path3=$(sc start bash 3>&-)
    sc close "$shell_path3"

    run -0 sc list -a
    assert_output --partial "$shell_path"
    assert_output --partial "$shell_path2"
    assert_output --partial "$shell_path3"
}

@test "Run a command in a bash and see the output" {
    local shell_path
    shell_path=$(sc start bash 3>&-)

    sc command "$shell_path" echo hello

    assert_file_exists "${shell_path}/shell_output"
    assert_file_contains "${shell_path}/shell_output" 'hello'
    assert_file_exists "${shell_path}/shell_command"
    assert_file_contains "${shell_path}/shell_command" 'echo hello'
    assert_file_exists "${shell_path}/shell_exit"
    assert_file_contains "${shell_path}/shell_exit" '0'

}
