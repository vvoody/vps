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
CHKREMOTE=/tmp/CHECKSUMS.md5.remote
DEBUG=no
GOTNEW=no

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
    $DROPBOX_UPLOADER download $REMOTE_DIR/CHECKSUMS.md5 $CHKREMOTE &>/dev/null
    # leave a bug here. Failure was caused by other reasons, not non-existed.
    if [ $? -eq 0 ]; then
        cat $CHKREMOTE
        chmod 600 $CHKREMOTE
    else
        # first time upload, no remote files.
        cat <<EOF
EOF
    fi
}

# find . -name ".git" -prune -o -type f -o -type l
# find . -type f -print0 | xargs -0 md5sum
# find . -name ".git" -prune -o -print0 | xargs -0 md5sum 2>/dev/null
function make_local_checksums() {
    find . -type f -print0 | xargs -0 md5sum | sort -k 2 -t ' '
}

function list_files_to_be_uploaded() {
    # only match lines like '+f91ee911b8d5ca5f42b9a3fc6ff6c570  ./sb/jdk-7u7-x86_64-1.txz'
    # and ignore CHECKSUMS.md5
    diff -u <(get_remote_checksums) <(make_local_checksums) | egrep -i '^\+[a-z0-9]' | grep -v "CHECKSUMS.md5"
}

# Usage: $0 to_be_uploaded_dir/
if [ $# -eq 1 ]; then
    if [ -d "$1" ]; then
        CWD=$(pwd)
        pushd $CWD >/dev/null
        cd "$1"
        while read x local_file ; do     # line looks like '+f91ee911b8d5ca5f42b9a3fc6ff6c570  ./jdk-7u7-x86_64-1.txz'
            MD5=${x:1}          # skip leading '+' char
            REMOTE_FILE=${local_file#./}
            if [ $DEBUG == "yes" ]; then
                echo -n $DROPBOX_UPLOADER
                green " upload"
                yellow " $local_file"
                echo -n " ${REMOTE_DIR}/"
                yellow "$REMOTE_FILE"
                echo
            else
                $DROPBOX_UPLOADER upload "$local_file" "$REMOTE_DIR"/"$REMOTE_FILE"
                # add new checksums in local to CHECKSUMS.md5, this makes multiple repos co-exist.
                if [ $? -eq 0 ]; then
                    echo "$MD5  $local_file" >> $CHKREMOTE
                fi
            fi
            GOTNEW=yes
        done < <(list_files_to_be_uploaded)

        if [ $GOTNEW == "yes" ]; then
            echo "Updating CHECKSUMS.md5..."
            # upload updated CHECKSUMS.md5 to remote
            cat $CHKREMOTE | sort -k 2 -t ' ' | tee $CHKREMOTE >/dev/null
            $DROPBOX_UPLOADER upload $CHKREMOTE $REMOTE_DIR/CHECKSUMS.md5
        else
            echo "Nothing new, did nothing."
        fi
        echo "Done."
        pushd $CWD >/dev/null
    else
        die "no such directory! at line $LINENO."
    fi
else
    die "Please specify one target directory! at line $LINENO."
fi
