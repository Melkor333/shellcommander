# TODO: Make sure we can run the whole unsharing by checking that everything necessary is provided
run() {
    local testname="$1"
    shift
    unshare --kill-child --mount-proc -Unfp test/bats/bin/bats $@ "test/$testname.bats"
}

help() {
    echo "Run the bats test suite in an 'unshare'. This ensures no background processes are leaked.

Usage:
 $0 run TEST [BATS ARGUMENTS]

    TEST     any of the files under test/TEST.bats (don't write the bats)"
    echo "Currently the only existing TEST is 'sc'"
    echo -e "\nFollowing the bats help:\n\n"
    test/bats/bin/bats --help
    exit
}

$@
