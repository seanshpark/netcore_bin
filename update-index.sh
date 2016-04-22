#!/bin/sh

for repo in `find . -maxdepth 1 -type d`; do
	if [ "$repo" != "." ]; then
		git -C $repo pull --rebase
	fi
done

/opt/local/opengrok/bin/OpenGrok update
