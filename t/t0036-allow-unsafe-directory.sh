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

test_expect_success '--assume-unsafe prevents execution if not in safe.directory' '
	sane_unset GIT_TEST_ASSUME_DIFFERENT_OWNER &&
	git status &&
	test_must_fail git --assume-unsafe status 2>err &&
	grep "dubious ownership" err
'

test_expect_success 'GIT_ASSUME_UNSAFE prevents execution if not in safe.directory' '
	test_must_fail env GIT_ASSUME_UNSAFE=1 \
			   git status 2>err &&
	grep "dubious ownership" err
'

test_expect_success 'safe.assumeUnsafe on the command line' '
	test_must_fail git -c safe.assumeUnsafe="true" status 2>err &&
	grep "dubious ownership" err
'

test_expect_success 'safe.assumeUnsafe in the environment' '
	test_must_fail env GIT_CONFIG_COUNT=1 \
	    GIT_CONFIG_KEY_0="safe.assumeUnsafe" \
	    GIT_CONFIG_VALUE_0="true" \
	    git status 2>err &&
	grep "dubious ownership" err
'

test_expect_success 'safe.assumeUnsafe in GIT_CONFIG_PARAMETERS' '
	test_must_fail env GIT_CONFIG_PARAMETERS="${SQ}safe.assumeUnsafe${SQ}=${SQ}true${SQ}" \
	    git status 2>err &&
	grep "dubious ownership" err
'

test_expect_success 'ignoring safe.assumeUnsafe in repo config' '
	git config safe.assumeUnsafe "false" &&
	git config --global safe.assumeUnsafe "true" &&
	test_must_fail git status 2>err &&
	grep "dubious ownership" err
'

test_expect_success 'allow-unsafe must override assume-unsafe' '
	env GIT_ASSUME_UNSAFE=1 git --allow-unsafe status
'

test_done
