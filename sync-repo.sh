#!/bin/bash
#
#   Copyright 2016 by Sung-Jae Lee (sjlee@mail.com)
#

function sync 
{
	BRANCH=$(git -C $1 branch | grep '*' | cut -d' ' -f2-)
	UPSTREAM=$(git -C $1 remote | grep -v origin)

	echo ">>>> sync [$1] to upstream <<<<"
	git -C $1 fetch --all
	git -C $1 merge $UPSTREAM/$BRANCH
	git -C $1 push
	git -C $1 pull --rebase
	echo
}

case $# in
	0)
		for repo in $(ls)
		do
			if [ -e $repo/.git ]
			then
				sync $repo
			fi
		done
		;;
	*)
		while [ -n "$1" ] && [ -e $1/.git ]
		do
			sync $1
			shift
		done
		;;
esac
