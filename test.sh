#!/bin/sh

##################
# Options Parsing

case "$1" in
	-s|--summary|--summarize) QUIET=-q; say () { :; } ;;
	*) QUIET=; say () { echo "$@"; } ;;
esac

####################
# Testing Framework

asserts_count=0
fails_count=0

assert () {
	asserts_count=$(($asserts_count + 1))
	msg="$1"
	shift
	if test "$@"
	then
		say "Assert: $msg"
	else
		fails_count=$(($fails_count + 1))
		echo "!!! Failed Assert: $msg"
	fi
}

#########
# Utils: commit_non_hash_info(), assert_is_subcommit_of()

commit_non_hash_info () {
	git log $1 --no-walk --pretty='format:%an%n%ae%n%ai%n%cn%n%ce%n%ci%n%B'
}

#######
# Main

say '0. setup empty git repo, empty folders'
rm -rf test-repo
git init test-repo $QUIET
cd test-repo

mkdir -p path/to/sub/

say
say '1. create and add foo in Sub, commit to Main'
echo foo > path/to/sub/foo
git add path/to/sub/foo
git commit -m 'Add path/to/sub/foo' $QUIET

say
say '2. split out commit history of just Sub, rooted in path/to/sub/'
../git-subhistory.sh split path/to/sub/ -b subproj -v $QUIET
assert 'tree of subproj matches subtree of master' \
	$(git rev-parse subproj:) = $(git rev-parse master:path/to/sub/)
assert 'subproj commit other info matches master' \
	"$(commit_non_hash_info subproj)" = "$(commit_non_hash_info master)"

###############
# Test Summary

say
if test $fails_count = 0
then
	echo "All $asserts_count tests pass"
else
	echo "$fails_count tests failed (out of $asserts_count)"
fi
exit $fails_count