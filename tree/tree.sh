#!/usr/bin/env bash
# tree: Linux tree shim for cygwin.
# Author: Shannon Moeller <me@shannonmoeller.com>
# vim: set filetype=sh:

# variables
IFS=$'\n'
len=100

# get options (ignore all but -a and -L)
while getopts 'adfgilno:pqrstuxACDFI:H:L:P:NRST:' opt; do
	case "$opt" in
		a) all="-A";;
		L) len="$OPTARG";;
	esac
done

# make argv useful again
shift $(( $OPTIND - 1 ))

# emulator
list() {
	local list=( $(ls -1 $all $1 ) ) last=${list[@]: -1}

	for f in ${list[@]}; do
		# ignore git data and vim swap files
		if [[ $f == ".git" || $f =~  "\.swp$" ]]; then
			continue;
		fi

		# prefixes
		if [[ $f == $last ]]; then
			pst="\`"
			pre=" "
		else
			pst="|"
			pre="|"
		fi

		# display
		echo "$3$pst-- $f"

		# recurse
		if [[ $2 -lt $len && -d $1/$f ]]; then
			list $1/$f $(( $2 + 1 )) "$3$pre   "
		fi
	done
}

# execute
dir=${1:-.}
echo $dir
list $dir 1
