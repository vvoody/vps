#!/usr/bin/bash

# Copyright 2012 vvoody <vvoodywang@gmail.com>
#
# All rights reserved.
#
# This script just does a simple thing:
#
#   upload built slackware packages(*.t?z) and corresponding source
#   build files to your backup Dropbox.
#
# See tgz2dropbox.README for more information.
#
# Requirements & Thanks:
#   BASH Dropbox Uploader
#   cURL

DROPBOX_UPLOADER=~/bin/dropbox_uploader.sh
REMOTE_DIR=slackware/slackware-$(cat /etc/slackware-version | cut -d' ' -f2)/$(uname -m)

# Thanks these colorful codes of github.com/authy-ssh
export TERM="xterm-256color"
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2; tput bold)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)

function red() {
   echo -ne "$RED$*$NORMAL"
}

function green() {
   echo -ne "$GREEN$*$NORMAL"
}

function yellow() {
   echo -ne "$YELLOW$*$NORMAL"
}

#
function die() {
    echo "$@"
    exit 1
}

#
function init_dir() {
    echo
}

function get_slackware_version() {
    if [ -r /etc/slackware-version ]; then
        ver=$(cat /etc/slackware-version | cut -d' ' -f 2)
        echo $ver
    else
        echo "Oops, you are not running a Slackware box, do nothing..."
        exit 1
    fi
}

# uploading a local to remote or not depends on diff between local
# checksums and remote's.
function get_remote_checksums() {
    TMPFILE=/tmp/tgz2dropbox.tmp
    $DROPBOX_UPLOADER download $REMOTE_DIR/CHECKSUMS.md5 $TMPFILE &>/dev/null
    if [ $? -eq 0 ]; then
        cat $TMPFILE
    else
        # 'echo -n' will truncate first line
        cat <<EOF

EOF
    fi
}

# find . -type f -print0 | xargs -0 md5sum
# find . -name ".git" -prune -o -print0 | xargs -0 md5sum 2>/dev/null
function make_local_checksums() {
    find . -type f -print0 | xargs -0 md5sum | sort -k 2 -t ' '
}

function list_files_to_be_uploaded() {
    # first 4 lines of diff are no use
    diff -u <(get_remote_checksums) <(make_local_checksums) | tail -n +5 | egrep '^\+'  | awk '{print $2}'
}

# Usage: $0 to_be_uploaded_dir/
if [ $# -eq 1 ]; then
    if [ -d "$1" ]; then
        CWD=$(pwd)
        pushd $CWD >/dev/null
        cd "$1"
        while read line; do
            REMOTE_FILE=${line#./}
            if [ -v DEBUG ]; then
                echo -n $DROPBOX_UPLOADER
                green " upload"
                yellow " $line"
                echo -n " ${REMOTE_DIR}/"
                yellow "$REMOTE_FILE"
                echo
            else
                $DROPBOX_UPLOADER upload "$line" "$REMOTE_DIR"/"$REMOTE_FILE"
            fi
        done < <(list_files_to_be_uploaded)
        $DROPBOX_UPLOADER upload CHECKSUMS.md5 $REMOTE_DIR/CHECKSUMS.md5
        pushd $CWD >/dev/null
    else
        die "no such directory! at line $LINENO."
    fi
else
    die "Please specify one target directory! at line $LINENO."
fi
