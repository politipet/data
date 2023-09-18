fetch:
	./fetch-signatures-counts.sh

update:
	git config user.name "[Bot]"
	git config user.email "actions@github.com"
	git add i-*.txt
	git add all-data.txt
	git add all-stat.txt
	git add all-closed.txt
	git commit -m "Update petitions counts" || true
	git push origin HEAD:master

closed:
	make -f fetch.mk closed
	:
	git add all-closed.txt
	nb_items=`git diff --cached | grep -F +i- | wc -l` \
	\
	git commit -m "update closed list ($$nb_items)" || true
	git show | grep '+i-' | sed "$(link.sed)"

link.sed = \
	s,\+,https://petitions.assemblee-nationale.fr/initiatives/, ;\
	s, c-.*,,

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

diff-stats:
	: diff stats since $(since)
	@git diff --word-diff `\
		git lg --oneline --since="$(since)" all-data.txt \
		| tail  -1 | cut -d ' ' -f 2 \
	` all-data.txt \
	| grep '^i-.*\[-' \
	| sed 's/[-+]/ /g' \
	| awk '{print $$1 "-" $$2, $$3 "-" $$4, $$8-$$6, $$8}' \
	| sort > .1
	@sed '/^#/ d' Petitions.txt | sort > .2
	@join .1 .2 -a 1 | sort -n -k3 \
		| sed 's/ /\t/3; s/ /\t/3;'
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
