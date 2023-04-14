setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/..:$PATH"
    # set up (even when we test that lateron :D )
    eval "$(sc init)"
}

teardown(){
    rm -rf "$SC_PATH"
}


@test "test init" {
    run sc init /tmp/SC_BATS_TEST
    assert_output --partial /tmp/SC_BATS_TEST
    rm -r "/tmp/SC_BATS_TEST"
}

@test "Run Help" {
    run sc help
    assert_output --partial 'TODO'
}

@test "Start a bash in the Background" {
    sc start bash
    assert_output '1'
    assert


}
