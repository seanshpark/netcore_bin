#!/bin/sh

OPENGROK=/opt/opengrok/bin/OpenGrok
if ! [ -x $OPENGROK ]; then
	OPENGROK=/opt/local/opengrok/bin/OpenGrok
fi

for repo in $(ls)
do
	if [ -e $repo/.git ]; then
		git -C $repo pull --rebase
	fi
done

time $OPENGROK update
