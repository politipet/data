#!/bin/bash

since=${*:-2 weeks}
data="all-data.txt"
TZ="Europe/Paris"

main() {
	sum_votes | sum_days | bars
}

sum_votes() {
	git log --since="$since" 		\
		--format=%h $data |		\
	while read n; do {
		get_commit_date $n
		get_commit_votes $n
		} | xargs
	done
}

sum_days() {
	awk '
		!day	{ day = $1 }
		END	{ print day, n }
		$1 != day {
			print day, n
			fflush()
			day = $1; n = $3
			next
		}
		{ n += $3 }
	'
}

bars() {
	awk '{
		bar = sprintf("|%*s", int($2/10 + .5), "")
		gsub(" ", "=", bar)
		print $1 "\t" $2 "\t" bar
		fflush()
	}'
}

get_commit_votes() {
	git show $1 $data			\
	| get_score_diffs_from_diff		\
	| discard_closed_or_readded		\
	| awk '{ t += $3 } END { print t }'
}

discard_closed_or_readded() {
	awk '	$5 == "-"		{next} # closed
		$5 == "+" && $3 > 3000	{next} # re-added
	{print}
	'
}

get_score_diffs_from_diff() {
	egrep '[+-]i-' | sed 's/i-/ i-/'	\
	| awk '{
		id = $2; comm = $3; score = $4
		s[id] = score
		c[id] = comm
		d[id] += int($1 score)
		x[id] = (x[id] $1) == "-+" ? "" : $1
	}
	END { for (id in s) print id, c[id], d[id], s[id], x[id] }
	'
}

get_commit_date() {
	TZ=$TZ git show -s $1			\
		--format=%ad 			\
		--date=format-local:'%F %T'
}

#sum_votes | sed 's/ /\t/2'

main
