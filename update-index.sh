#!/bin/sh

#OPENGROK=/opt/local/opengrok/bin/OpenGrok
OPENGROK=/opt/opengrok/bin/OpenGrok

for repo in `find . -maxdepth 1 -type d`; do
	if [ "$repo" != "." ]; then
		git -C $repo pull --rebase
	fi
done

time $OPENGROK update
