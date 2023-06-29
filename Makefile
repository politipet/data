fetch:
	./fetch-signatures-counts.sh

update:
	git config user.name "[Bot]"
	git config user.email "actions@github.com"
	git add i-*.txt
	git add all-data.txt
	git add all-stat.txt
	git commit -m "Update petitions counts" || true
	git push origin HEAD:master

since ?= 10 days
stats:
	: hits stats since $(since)
	@git log --stat --since '$(since)' \
		| egrep 'i-.*\+$$' \
		| sed 's/ | .*//' | sort | uniq -c \
		| cut -c 1-8 > .1
	@sed '/^#/ d' Petitions.txt | sort > .2
	@paste .1 .2 | sort -k 1nr
	@\rm .1 .2

pan-stat:
	cat all-data.txt \
	| cut -d ' ' -f 2 | sort | uniq -c \
	| egrep -v 'c-$$' \
	| sed 's:c-.*::' \
	> $@
	paste $@ commissions.txt > all-stat.txt
	\rm $@

update: pan-stat
