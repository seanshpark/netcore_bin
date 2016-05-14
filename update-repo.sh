#!/bin/sh

for repo in $(ls) 
do
	if [ -e $repo/.git ]; then
		echo "Update git repository [$repo]"
		git -C $repo pull --rebase
	fi
done
