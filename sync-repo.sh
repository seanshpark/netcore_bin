#!/bin/sh

for repo in `find . -maxdepth 1 -type d`; do
	if [ "$repo" != "." ]; then
		echo "Sync git repository to upstream [$repo]"
		BRANCH=`git -C $repo branch | grep '*' | cut -d' ' -f2-`
		UPSTREAM=`git -C $repo remote | grep -v origin`
		git -C $repo fetch --all
		echo "git -C $repo merge $UPSTREAM/$BRANCH"
		git -C $repo merge $UPSTREAM/$BRANCH
		git -C $repo push
		git -C $repo pull --rebase
	fi
done
