fetch:
	@echo "no $@ (debug)"

update:
	@echo "no $@ (debug)"

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
		 $(data) | egrep '^\[-' | sed 's/\[-//; s/-\].*//'

new: since ?= 2 days
new:
	: new since $(since)
	@git log --since "$(since)" --format=%h |	\
	while read rev; do				\
		git show $$rev $(data)			\
		| egrep '^\+.* 0$$' | tr -d +		\
		| cut -d ' ' -f 1,2;			\
	done						\
	| sed "s,^,https://petitions.assemblee-nationale.fr/initiatives/,"

extract. extract.id:
	@echo "please specify <id>"

extract.%:
	@git log --reverse --format=%h $(data) |	\
	while read n; do				\
	git show $$n $(data) | egrep "^[+]i-$*" | {	\
	read line && {					\
		TZ=$(TZ) 				\
		git log $$n -1 --format=%ad --date=format-local:'%F %T'	;\
		echo $$line						;\
	} | xargs; }					\
	done | awk '{print $$1, $$2 "\t" $$5}'

data = all-data.txt
TZ  ?= Europe/Paris

since ?= 10 days
diff-stats:
	: diff stats since $(since)
	@git diff --word-diff `\
		git lg --oneline --since="$(since)" $(data) \
		| tail  -1 | cut -d ' ' -f 2 \
	` $(data) \
	| sed 's/\]i/]\ni/g' \
	| grep '^i-.*\[-' \
	| sed 's/c- /c-na /' \
	| sed 's/[-+]/ /g' \
	| awk '{print $$1 "-" $$2, $$3 "-" $$4, $$8-$$6, $$8}' \
	| sort > .1
	@sed '/^#/ d' Petitions.txt | sort > .2
	@join .1 .2 -a 1 | sort -n -k3 \
		| sed 's/ /\t/3; s/ /\t/3;'
	@\rm .1 .2

all-votes:
	git log --since="1 day" --format=%h $(data)

_all-votes:
	./stats.sh 1 day | head -1 > .1
	head -1 $(out) > .2
	if [ `cut -f1 .1` = `cut -f1 .2` ]; then \
		sed 1d $(out) > .2		;\
	else					 \
		mv $(out) .2			;\
	fi
	cat .1 .2 > $(out)

all-votes: out = $@.txt


pan-stat:
	cat $(data) \
	| cut -d ' ' -f 2 | sort | uniq -c \
	| egrep -v 'c-$$' \
	| sed 's:c-.*::' \
	> $@
	paste $@ commissions.txt > all-stat.txt
	\rm $@

update: pan-stat all-votes
