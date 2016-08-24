#!/bin/bash
#
#   Copyright 2016 by Sung-Jae Lee (sjlee@mail.com)
#

#
# set default configuration
#
COMMAND_LINE="$@"
NEW_BRANCH=
BRANCH=

function usage
{
    echo ''
    echo "Usage: [BASE_PATH=<git_base>] $(basename $0) [options] <command>"
    echo ''
    echo '  [command]'
    echo '           update : update current branch from origin'
    echo '             sync : sync master [upstream/master] to [origin/master]'
    echo '        distclean : git clean -xdf'
    echo '          version : display HASH of current working branch'
    echo ''
    echo '  [option]'
    echo '         --branch : update current branch from origin'
    echo '     --new-branch : update current branch from origin'
    echo ''
}

#
# print usage
#
if [ $# -eq 0 ]; then
    usage
    exit
fi

#
# etc.
#
if [ -z "$BASE_PATH" ]; then
    BASE_PATH=$(pwd)
fi

LOG_FILE="$BASE_PATH/$(basename ${0}).log"
TIME="time"

#
# define functions
#

function sync
{
    local STASHED=0
    local REPO=$1
    local NEW_BRANCH=$2

    if [ -e "$REPO/.git" ]; then
        UPSTREAM=$(git -C $REPO remote | grep -v origin)
        BRANCH=$(git -C $REPO branch | grep '^*' | cut -d' ' -f2-)

        echo ">>>> [$REPO]: sync branch [master] to [$UPSTREAM/master] <<<<"

        STASH_RESULT=$(git -C $REPO stash)
        if [ "$STASH_RESULT" != "No local changes to save" ]
        then
            STASHED=1
        fi

        if [ "$BRANCH" != "master" ]
        then
            git -C $REPO checkout master
        fi

        git -C $REPO fetch --all
        git -C $REPO merge $UPSTREAM/master
        git -C $REPO push
        git -C $REPO pull --rebase

        HASH=$(git -C $REPO log -1 --format=%H)
        echo "BRANCH:master"
        echo "HASH:$HASH"


        if [ "$BRANCH" != "master" ]
        then
            echo ""
            echo "[$REPO]: checkout branch [$BRANCH]"
            git -C $REPO checkout $BRANCH
            HASH=$(git -C $REPO log -1 --format=%H)
            echo "BRANCH:$BRANCH"
            echo "HASH:$HASH"
            echo ""
        fi

        if [ -n "$NEW_BRANCH" ]
        then
            echo ""
            echo "[$REPO]: make branch [$NEW_BRANCH] from [master], and checkout"
            git -C $REPO branch $NEW_BRANCH master
            git -C $REPO checkout $NEW_BRANCH
            HASH=$(git -C $REPO log -1 --format=%H)
            echo "BRANCH:$BRANCH"
            echo "HASH:$HASH"
            echo ""
        fi

        if [ "$STASHED" == "1" ]
        then
            git -C $REPO stash apply
        fi
    fi
}

function sync_repo 
{
    case $# in
        0)
            for repo in $(ls $BASE_PATH)
            do
                sync $repo $NEW_BRANCH
            done
            ;;
        *)
            while [ -n "$1" ] && [ -e $1/.git ]
            do
                sync $1 $NEW_BRANCH
                shift
            done
            ;;
    esac
}

function update
{
    if [ -e "$1/.git" ]; then
        BRANCH=$(git -C $1 branch | grep '*' | cut -d' ' -f2-)
        HASH=$(git -C $1 log -1 --format=%H)

        echo ">>>> update [$1] <<<<"
        git -C $1 pull --rebase
        echo "BRANCH:$BRANCH"
        echo "HASH:$HASH"
        echo ""
    fi
}

function update_repo 
{
    case $# in
        0)
            for repo in $(ls $BASE_PATH)
            do
                update $repo
            done
            ;;
        *)
            while [ -n "$1" ] && [ -e $1/.git ]
            do
                update $1
                shift
            done
            ;;
    esac
}

function distclean 
{
    for repo in $(ls $BASE_PATH)
    do
        if [ -e $repo/.git ]; then
            git -C $repo clean -xdf
        fi
    done
}

function version
{
    if [ -e "$1/.git" ]; then
        BRANCH=$(git -C $1 branch | grep '^*' | cut -d' ' -f2-)
        HASH=$(git -C $1 log -1 --format=%H)

        echo "[$1]"
        echo "BRANCH:$BRANCH"
        echo "HASH:$HASH"
        echo ""
    fi
}

function show_version 
{
    case $# in
        0)
            for repo in $(ls $BASE_PATH)
            do
                version $repo
            done
            ;;
        *)
            while [ -n "$1" ] && [ -e $1/.git ]
            do
                version $1
                shift
            done
            ;;
    esac
}

#
# parse command-line options
#
while [ -n "$1" ]
do
    case $1 in
        distclean)
            distclean | tee -a $LOG_FILE
            exit
            ;;
        sync)
            shift
            sync_repo $@
            exit
            ;;
        update)
            shift
            update_repo $@
            exit
            ;;
        version)
            shift
            show_version $@
            exit
            ;;
        --branch=*)
            BRANCH=${1#*=}
            ;;
        --new-branch=*)
            NEW_BRANCH=${1#*=}
            ;;
        *)
            EXTRA_OPTIONS="${EXTRA_OPTIONS} $1"
            ;;
    esac
    shift
done
