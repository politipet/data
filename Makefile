fetch:
	make -f fetch.mk all-data
	cat Petitions.txt | egrep -v '^#' | cut -f 1 |		\
	while read pet; do					\
		curr_val=`grep $$pet $(data) | cut -d ' ' -f 3`	;\
		last_val=`tail -1 $$pet.txt | cut -f 2`		;\
		[ "$$curr_val" != "$$last_val" ] || continue	;\
		timestamp=`TZ=$(TZ) date +'%F %T'`		;\
		echo "$$timestamp\t$$curr_val" >> $$pet.txt	;\
	done

update:
	git config user.name "[Bot]"
	git config user.email "actions@github.com"
	git add i-*.txt
	git add all-*.txt
	git commit -m "cron update" || true
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
	| tr '\n' : | sed 's,\]:\[[^{]*,],g' | tr : '\n' \
	| grep '^i-.*\[-' \
	| sed 's/c- /c-. /' \
	| sed 's/[-+]/ /g' \
	| awk '{print $$1 "-" $$2, $$3 "-" $$4, $$8-$$6, $$8}' \
	| sort > .1
	@sed '/^#/ d' Petitions.txt | sort > .2
	@join .1 .2 -a 1 | sort -n -k3 \
		| sed 's/ /\t/3; s/ /\t/3;'
	@\rm .1 .2

all-votes:
	./stats.sh 2 days | head -2 > .1
	sed "0,/`tail -1 .1 | cut -f1`/ d" $@.txt > .2
	cat .1 .2 > $@.txt

_av.pre:
	git fetch --shallow-since="3 days"
	@git config user.name _; git config user.email _@_
	@git add $(data); git commit --allow-empty -q -m _
_av.post:
	@git reset HEAD^

_all-votes: _av.pre all-votes _av.post

all-stat:
	cat $(data) \
	| cut -d ' ' -f 2 | sort | uniq -c \
	| egrep -v 'c-$$' \
	| sed 's:c-.*::' \
	> $@
	cut -f 2 commissions.txt | paste $@ - > $@.txt
	\rm $@

update: all-stat _all-votes
