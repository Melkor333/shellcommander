# Testing
The testing is done with [bats](https://github.com/bats-core/bats-core).

Run the basic `sc` tests:
```
test/bats/bin/bats test/sc.bats
```

## Updating the test framework

Since `git submodule` is evil, I chose to use `git subtree`:
```
git subtree pull -P test/bats https://github.com/bats-core/bats-core.git master
git subtree pull -P test/test_helper/bats-support https://github.com/bats-core/bats-support.git master
git subtree pull -P test/test_helper/bats-file https://github.com/bats-core/bats-file.git master
git subtree pull -P test/test_helper/bats-assert https://github.com/bats-core/bats-assert.git master
```
