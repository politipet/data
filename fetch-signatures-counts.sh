#!/bin/bash

poll() {
	target=$1
	curr_val=$(grep $target all-data.txt | cut -d ' ' -f 3)
	last_two=$(tail -3 $target.txt | cut -f 2)
	is_still=$(echo -e "$last_two\n$curr_val" | sort -u | wc -l)

	[ "$is_still" != 1 ] || sed -i "$ d" $target.txt

	timestamp=$(TZ='Europe/Paris' date +'%F %T')
	echo -e "$timestamp\t$curr_val" >> $target.txt
}

main() {
	petitions=$(cat Petitions.txt | egrep -v ^# | cut -f 1)

	make -f fetch.mk all-data

	for i in $petitions; do
		poll $i &
	done
	wait
}

main
