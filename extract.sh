#!/bin/bash

usage() {
	echo "usage: $0 <pet num>"
	exit $1
}

shopt -s extglob; num="+([0-9])"

case $1 in
	$num)
		TARGET=i-$1 ;;
	-h|--help)
		usage 0 ;;
	*)
		usage 1 ;;
esac

data=all-data.txt

git log --reverse --format=%h $data |\
while read n; do
	git show $n $data | egrep "^[+]$TARGET" | {
	read line && {
		git log -1 $n --format=%ad --date=format:'%F %T'
		echo $line
	} | xargs; }
done | awk '{print $1, $2 "\t" $5}'
