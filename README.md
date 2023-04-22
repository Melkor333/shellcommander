# Usage

Start a very simple bash connection
```
./sc start bash
```

# Testing
The testing is done with [bats](https://github.com/bats-core/bats-core).

Since processes can be leaked when a test fails, `unshare` is used to make sure everything is cleaned up after a test.
Run the basic tests:

```shell-session
# Run the currently only test file `test/sc.bats`:
./test.sh run sc
# get help
./test.sh help
```

## Updating the test framework

Since `git submodule` is evil, I chose to use `git subtree`:
```
git subtree pull -P test/bats https://github.com/bats-core/bats-core.git master
git subtree pull -P test/test_helper/bats-support https://github.com/bats-core/bats-support.git master
git subtree pull -P test/test_helper/bats-file https://github.com/bats-core/bats-file.git master
git subtree pull -P test/test_helper/bats-assert https://github.com/bats-core/bats-assert.git master
```
