#!/bin/bash

fetch() {
	curl -s https://petitions.assemblee-nationale.fr/initiatives/$1 \
	| grep progress__bar__number \
	| sed 's/[^>]*>//; s/<.*//; s/ //'
}

poll() {
	target=$1
	curr_val=$(fetch $target)
	last_val=$(tail -1 $target.txt | cut -f 2)

	[ "$curr_val" != "$last_val" ] || return 0

	timestamp=$(TZ='Europe/Paris' date +'%F %T')
	echo -e "$timestamp\t$curr_val" >> $target.txt
}

main() {
	petitions=$(cat Petitions.txt | egrep -v ^#)

	for i in $petitions; do
		poll $i &
	done
	wait
}

main
