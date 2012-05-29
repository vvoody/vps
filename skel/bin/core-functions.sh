#!/usr/bin/bash

# pkgbase() and package_name() are from Slackware pkgtools package.
# cutpkg() are from slackpkg source code, much faster then above.
# cutpkg function requires slackpkg package.

# Got the name of a package, without version-arch-release data
#
function cutpkg() {
	echo ${1/%.t[blxg]z/} | awk -F- -f /usr/libexec/slackpkg/cutpkg.awk
}

function pkgbase() {
	PKGEXT=$(echo $1 | rev | cut -f 1 -d . | rev)
	case $PKGEXT in
		'tgz' )
		PKGRETURN=$(basename $1 .tgz)
		;;
		'tbz' )
		PKGRETURN=$(basename $1 .tbz)
		;;
		'tlz' )
		PKGRETURN=$(basename $1 .tlz)
		;;
		'txz' )
		PKGRETURN=$(basename $1 .txz)
		;;
		*)
		PKGRETURN=$(basename $1)
		;;
	esac
	echo $PKGRETURN
}

function package_name() {
	STRING=$(pkgbase $1)
	# Check for old style package name with one segment:
	if [ "$(echo $STRING | cut -f 1 -d -)" = "$(echo $STRING | cut -f 2 -d -)" ]; then
		echo $STRING
	else # has more than one dash delimited segment
		# Count number of segments:
		INDEX=1
		while [ ! "$(echo $STRING | cut -f $INDEX -d -)" = "" ]; do
			INDEX=$(expr $INDEX + 1)
		done
		INDEX=$(expr $INDEX - 1) # don't include the null value
		# If we don't have four segments, return the old-style (or out of spec) package name:
		if [ "$INDEX" = "2" -o "$INDEX" = "3" ]; then
			echo $STRING
		else # we have four or more segments, so we'll consider this a new-style name:
			NAME=$(expr $INDEX - 3)
			NAME="$(echo $STRING | cut -f 1-$NAME -d -)"
			echo $NAME
			# cruft for later ;)
			#VER=$(expr $INDEX - 2)
			#VER="$(echo $STRING | cut -f $VER -d -)"
			#ARCH=$(expr $INDEX - 1)
			#ARCH="$(echo $STRING | cut -f $ARCH -d -)"
			#BUILD="$(echo $STRING | cut -f $INDEX -d -)"
		fi
	fi
}

# after OS reinstallation, there are some unnecessary packages installed.
# so we need a list of showing the differences between installed packages
# and slackpkg's template(base packages needed).
# use as "diff -u <(list_installed_pkgs) <(cat /etc/slackpkg/templates/xxx)"
# & remove the packages started with "-"
# $1 will be installed packages directory if given.
function list_installed_pkgs() {
    pkg_dir=/var/log/packages/
    if [ ! -z "$1" ]; then
        pkg_dir=$1
    fi
    for p in ${pkg_dir}/*; do
        echo $(cutpkg $(basename $p))
    done
}

# memory usage per process & sorted(desc)
# 'sort' is not necessary, ps --sort size(no '-') works.
function mu() {
    ps -eo size,pid,user,command --sort -size | awk '{ hr=$1/1024 ; printf("%13.2f Mb ",hr) } { for ( x=4 ; x<=NF ; x++ ) { printf("%s ",$x) } print "" }' | sort -n -k 1
}
