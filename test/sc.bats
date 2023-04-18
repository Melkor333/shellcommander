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
    HOME="${BATS_TEST_TMPDIR}"
    export SC_PATH=
    # set up (even when we test that lateron :D )
    eval "$(sc init ${BATS_TEST_TMPDIR}/SC)"
}

# TODO
#teardown() {
#
#}

@test "Run Help" {
    skip
    sc help
    assert_output --partial 'Usage'
}

@test "sc init returns and creates path" {
    # TODO: Mock mkdir to be really safe!
    out=$(sc init)
    dir="$(echo $out | cut -d'=' -f 2 | tr -d \")"
    [[ -d "$dir" ]]
    rm -r "$dir"
}

@test "sc init takes a custom path" {
    run sc init "${BATS_TEST_TMPDIR}/SC"
    assert_output --partial "${BATS_TEST_TMPDIR}/SC"
    assert_dir_exists "${BATS_TEST_TMPDIR}/SC"
    assert_file_exists "${BATS_TEST_TMPDIR}/SC/count"
    assert_file_contains "${BATS_TEST_TMPDIR}/SC/count" 0
}

@test "Start a bash in the Background" {
    # Regarding the 3>&-, see
    # see https://bats-core.readthedocs.io/en/stable/writing-tests.html#file-descriptor-3-read-this-if-bats-hangs

    # TODO: if we `run` it. it hangs :( also x=$(sc start bash) doesn't work sadly
    sc start bash 3>-
    assert_file_exists "${SC_PATH}/1_pid"
    PID=$(cat "${SC_PATH}/1_pid")
    # We check too fast for an existing command file :)

    # Command is stored
    assert_file_exists "${SC_PATH}/1_command"
    assert_file_contains "${SC_PATH}/1_command" 'bash'
    # count is increased
    assert_file_contains "${SC_PATH}/count" '1'

    # Input exists
    assert_fifo_exists "${SC_PATH}/1_input"

    # Output file gets created properly
    exec 20>"${SC_PATH}/1_input"
    echo 'echo output_file' >&20
    assert_file_exists "${SC_PATH}/1_output"
    assert_file_contains "${SC_PATH}/1_output" 'output_file'
    assert ps -p $PID > /dev/null
    # Exit
    echo 'exit' >&20

    # Command shouldn't exist
    refute ps -p $PID > /dev/null
    assert_file_exists "${SC_PATH}/1_exit"
    assert_file_contains "${SC_PATH}/1_exit" '0'
    assert_file_not_exists "${SC_PATH}/1_input"
}
