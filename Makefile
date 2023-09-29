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
	make gone --no-print-directory > .gone
	cat .gone all-closed.txt | sort -t - -k2nr > .closed
	mv .closed all-closed.txt
	git add all-closed.txt
	git commit -m "update closed list (`wc -l < .gone`)" || true
	:
	cat .gone | cut -f 1 -d ' ' | grep -f - Petitions.txt || true
	:
	@cat .gone | cut -f 1,3 -d ' ' \
	| sed "s,^,https://petitions.assemblee-nationale.fr/initiatives/,"

gone:
	 @git diff --word-diff \
		 `git log --oneline -1 all-closed.txt | cut -f 1 -d ' '` \
		 all-data.txt | egrep '^\[-' | sed 's/\[-//; s/-\]//'


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
	| sed 's/c- /c-na /' \
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
