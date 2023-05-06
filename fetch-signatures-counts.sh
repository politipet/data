#!/bin/bash

fetch() {
	curl -s https://petitions.assemblee-nationale.fr/initiatives/$1 \
	| grep progress__bar__number \
	| sed 's/[^>]*>//; s/<.*//; s/ //'
}

poll() {
	target=$1
	curr_val=$(fetch $target)
	last_two=$(tail -3 $target.txt | cut -f 2)
	is_still=$(echo -e "$last_two\n$curr_val" | sort -u | wc -l)

	[ "$is_still" != 1 ] || sed -i "$ d" $target.txt

	timestamp=$(TZ='Europe/Paris' date +'%F %T')
	echo -e "$timestamp\t$curr_val" >> $target.txt
}

main() {
	petitions=$(cat Petitions.txt | egrep -v ^# | cut -f 1)

	for i in $petitions; do
		poll $i &
	done
	wait
}

main
