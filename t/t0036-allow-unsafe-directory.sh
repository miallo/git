#!/bin/sh

test_description='verify safe.directory checks'

. ./test-lib.sh

GIT_TEST_ASSUME_DIFFERENT_OWNER=1
export GIT_TEST_ASSUME_DIFFERENT_OWNER

expect_rejected_dir () {
	test_must_fail git status 2>err &&
	grep "dubious ownership" err
}

test_expect_success 'safe.directory is not set' '
	expect_rejected_dir
'

test_expect_success '--allow-unsafe allows execution in unsafe directory' '
	git --allow-unsafe status
'

test_expect_success 'GIT_ALLOW_UNSAFE bool allows unsafe directory' '
	env GIT_ALLOW_UNSAFE=true \
	    git status
'

test_done
