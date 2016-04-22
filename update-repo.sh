#!/bin/sh

for repo in `find . -maxdepth 1 -type d`; do
	if [ "$repo" != "." ]; then
		echo "Update git repository [$repo]"
		git -C $repo pull --rebase
	fi
done
