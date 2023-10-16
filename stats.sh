#!/bin/bash

since=${*:-2 weeks}
data="all-data.txt"
TZ="Europe/Paris"

main() {
	sum_votes | sum_days | bars | tr ' ' '\t'
}

sum_votes() {
	git log --since="$since" 		\
		--format=%h $data |		\
	while read n; do {
		get_commit_date $n
		get_commit_votes $n
		} | xargs | tee /dev/fd/2
	done
}

sum_days() {
	awk '
		{ n += $3 }
		!day	{ day = $1 }
		END	{ print day, n }
		$1 != day {
			print day, n
			fflush()
			day = $1; n = $3
		}
	'
}

bars() {
	awk '{
		bar = sprintf("|%*s", int($2/10 + .5), "")
		gsub(" ", "=", bar)
		print $1, $2 "\t" bar
		fflush()
	}'
}

get_commit_votes() {
	git show --word-diff $1 $data		\
	| tee /dev/fd/2 \
	| fix_word_diff				\
	| tee /dev/fd/2 \
	| grep '^i-.*\[-'			\
	| tee /dev/fd/2 \
	| sed 's:[-+]: :g'			\
	| tee /dev/fd/2 \
	| awk '	{ n += ($8 - $6) }
		END { print n }' \
	| tee /dev/fd/2
}

get_commit_date() {
	TZ=$TZ git show -s $1			\
		--format=%ad 			\
		--date=format-local:'%F %T'
}

fix_word_diff() {
	sed 's:\]i:]\ni:g' |\
	tr '\n' : | sed 's,\]:\[[^{]*,],g' | tr : '\n'

}

#sum_votes | sed 's/ /\t/2'

main
