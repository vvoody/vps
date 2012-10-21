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
#
# CHECKSUMS.md5 and ChangeLog.txt are supposed to be only in the remote,
# they should not be uploaded as a new or changed file in the local repo dir.
# Everytime there is a change, this script will fetch 'ChangeLog.txt' from
# remote and invoke an editor to give you a chance to add stuff into
# 'ChangeLog.txt'

DROPBOX_UPLOADER=~/bin/dropbox_uploader.sh
REMOTE_DIR=slackware/slackware-$(cat /etc/slackware-version | cut -d' ' -f2)/$(uname -m)
CHKREMOTE=/tmp/CHECKSUMS.md5.remote
DEBUG=no
GOTNEW=no
EDITOR=${EDITOR:-/usr/bin/vim}


function usage() {
    cat <<EOF
$0 <command> [<args>]

COMMANDS
         list [remote_dir]
          get remote_file    # download to current dir, be careful, maybe override
          put local_file [remote_dir]
       update local_repo
    changelog
EOF
}


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


# upload changed or new files to remote,
# not upload all file every time.
function do_update() {
    local_repo=$1    # dir contains slackware build files
    if [ -d "$local_repo" ]; then
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

            # invoke text edit to write ChangeLog.txt
            pushd /tmp
            $DROPBOX_UPLOADER download $REMOTE_DIR/ChangeLog.txt
            $EDITOR ChangeLog.txt
            while (true); do
                echo -n "Update ChangeLog.txt?(Y/n) "
                read ANS

                case $ANS in
                    y|Y|"")
                        $DROPBOX_UPLOADER upload /tmp/ChangeLog.txt $REMOTE_DIR/ChangeLog.txt
                        echo rm -i /tmp/ChangeLog.txt
                        break
                        ;;
                    n|N)
                        echo "ChangeLog.txt is not uploaded."
                        break
                        ;;
                    *)
                        echo "Please answer 'y' or 'n'."
                        ;;
                esac
            done
            pushd
        else
            echo "Nothing new, did nothing."
        fi
        echo "Done."
        pushd $CWD >/dev/null
    else
        die "no such directory! at line $LINENO."
    fi
}


CMD=$1
ARG=$2
ARG2=$3
case $CMD in
    list)
        $DROPBOX_UPLOADER list $REMOTE_DIR/$ARG
        ;;
    get)
        $DROPBOX_UPLOADER download $REMOTE_DIR/$ARG
        ;;
    put)
        lf=$(basename $ARG)
        $DROPBOX_UPLOADER upload $lf $REMOTE_DIR/$lf
        ;;
    update)
        do_update $ARG
        ;;
    changelog)
        pushd /tmp
        $DROPBOX_UPLOADER download $REMOTE_DIR/ChangeLog.txt
        less /tmp/ChangeLog.txt
        rm -i /tmp/ChangeLog.txt
        pushd
        ;;
    *)
        usage
        die "Please specify one target directory! at line $LINENO."
esac
