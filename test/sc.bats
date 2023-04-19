setup() {
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
    SC_PATH="${BATS_TEST_TMPDIR}"
}

# TODO
#teardown() {
#}

@test "Run Help" {
    skip
    sc help
    assert_output --partial 'Usage'
}

@test "Start a bash in the Background" {
    # Regarding the 3>&-, see
    # see https://bats-core.readthedocs.io/en/stable/writing-tests.html#file-descriptor-3-read-this-if-bats-hangs

    # TODO: if we `run` it. it hangs :( also x=$(sc start bash) doesn't work sadly
    local PID SHELL_PATH
    SHELL_PATH=$(sc start bash 3>-)

    assert_file_exists "${SHELL_PATH}/shell_pid"
    bash_pid=( $(cat "${SHELL_PATH}/shell_pid") )
    # We check too fast for an existing command file :)

    # Command is stored
    assert_file_exists "${SHELL_PATH}/shell_command"
    assert_file_contains "${SHELL_PATH}/shell_command" 'bash'
    # Input exists
    assert_fifo_exists "${SHELL_PATH}/shell_input"

    # Output file gets created properly
    exec 20>"${SHELL_PATH}/shell_input"
    echo 'echo output_file' >&20
    assert_file_exists "${SHELL_PATH}/shell_output"
    assert_file_contains "${SHELL_PATH}/shell_output" 'output_file'
    assert ps -p $bash_pid > /dev/null
    # Exit
    echo 'exit' >&20

    # Command shouldn't exist
    refute ps -p $bash_pid > /dev/null
    assert_file_exists "${SHELL_PATH}/shell_exit"
    assert_file_contains "${SHELL_PATH}/shell_exit" '0'
    assert_file_not_exists "${SHELL_PATH}/shell_input"
}
