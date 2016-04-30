#!/bin/sh

OPENGROK=/opt/opengrok/bin/OpenGrok
if ! [ -x $OPENGROK ]; then
	OPENGROK=/opt/local/opengrok/bin/OpenGrok
fi

for repo in `find . -maxdepth 1 -type d`; do
	if [ "$repo" != "." ]; then
		git -C $repo pull --rebase
	fi
done

time $OPENGROK update
