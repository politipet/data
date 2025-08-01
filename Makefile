fetch:
	make -f fetch.mk all-data
	cat Petitions.txt | sed '/^$$/ d' |			\
			sed '/not tracked/,$$ d' | cut -f 1 |	\
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
	make refetch --silent
	cat .gone all-closed.txt | sort -k1.3nr > .closed
	mv .closed all-closed.txt
	git add all-closed.txt
	git commit --untracked-files=no \
		-m "update closed list (`wc -l < .gone`)" || true
	:
	@cat .gone | cut -f 1 -d ' ' | grep -f - Petitions.txt || true
	:
	@cat .gone | cut -f 1,3 -d ' ' \
	| sed "s,^,https://petitions.assemblee-nationale.fr/initiatives/,"

refetch:
	for id in `cat .gone | cut -d ' ' -f 1`; do ( \
		echo $$id `\
		curl -sL petitions.assemblee-nationale.fr/initiatives/$$id \
		| grep progress__bar__number | sed 's/[^>]*>//; s/<.*//' \
		| tr -d ' ' \
		`) & \
		i=$$((i+1)); [ $$((i % 20)) = 0 ] && wait; \
	done > .gone.fresh; wait
	sort -k1.3nr .gone | cut -d ' ' -f 1,2 > .gone.sorted
	sort -k1.3nr .gone.fresh | join .gone.sorted - > .gone

gone:
	@git diff \
		 `git log --oneline -1 all-closed.txt | cut -f 1 -d ' '` \
		 $(data) \
	| egrep '[+-]i-' | sed 's/i-/ i-/' \
	| awk '{ if (t[$$2]) delete t[$$2]; else t[$$2] = $$0 } \
		END{ for (x in t) print t[x] }' \
	| egrep ^- | cut -d ' ' -f 2-

votes:
	@git log --reverse --format=%h $(votes) |	\
	while read v; do				\
		git checkout $$v $(votes)		;\
		clear; cat $(votes) | head 		;\
		sleep .1 				;\
	done


composed = $(shell cat compose.txt | sed 's/ =.*//')
composed: $(composed:%=%.compose)

%.compose:
	: compose $*
	@target=i-$*.txt ;\
	to_sum=`grep $* compose.txt | sed 's/.*= //' 	\
		| xargs | tr ' ' '\n' | sed 's/^/i-/'`	;\
	curr_val=`grep "$$to_sum" $(data)		\
		| cut -d ' ' -f 3 | xargs | tr ' ' + | bc`;\
	last_val=`tail -1 $$target | cut -f 2`		;\
	[ "$$curr_val" != "$$last_val" ] || exit 0	;\
	timestamp=`TZ=$(TZ) date +'%F %T'`		;\
	echo "$$timestamp\t$$curr_val" >> $$target	;\

update: composed


top-10:
	@git log --since "$(since)" --reverse		\
			--format=%h $(data) |		\
	while read v; do				\
		git checkout -q $$v $(data)		;\
		make --no-print-directory		\
			diff-stats > .$@		;\
		{ echo; $(commit-date) $$v; } >> .$@	;\
		clear && cat .$@			;\
		sleep .1 				;\
	done

commit-date = git show -s --format=%ad --date=format-local:'%F %T'

votes = all-votes.txt

new: since ?= 2 days
new:
	: new since $(since)
	@git diff \
		`git log --reverse --since "$(since)" --format=%h $(data) \
		 | head -1` \
		 $(data) \
	| egrep '[+-]i-' | sed 's/i-/ i-/' \
	| awk ' { if (t[$$2]) delete t[$$2]; else t[$$2] = $$1 } \
		{ c[$$2] = $$3 } \
		END{ for (x in t) print t[x], x, c[x] }' \
	| grep + | cut -d ' ' -f 2,3 \
	| sort \
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


rate-stat. rate-stat.id:
	@echo "please specify <id>"

rate-stat.%:
	@make day-scores.$* --no-print-directory \
	|awk '{printf("%s\t%d\t+%d\t%*c\n",	\
		$$1, $$2, $$3, $$3/10+.5, ".")}'	\
	| tr ' ' .

rate-split. rate-split.id:
rate-split.%:
	@make rate-stat.$* --no-print-directory \
	| while read l; do \
		d=`echo "$$l" | cut -f 1`; \
		[ "$$prev" = `date +%F -d "$$d - 1 day"` ] || echo; \
		prev=$$d; \
		echo "$$l"; \
	done | sed 1d \
	| sed 's/[.]/●/g' # or ▰ ▱ ▢


day-scores. day-scores.id:
day-scores.%:
	@cat i-$*.txt \
	| awk -v OFS='\t' '\
		d != $$1 && NR>1 {print d,s,s-p; p=s} \
		{s=$$3; d=$$1} \
		END {print d,s,s-p} \
	'

cross-talk: items ?= 2373 2360 2421 2396 2358 2428 2427
cross-talk: hist = 4
cross-talk:
	@for i in $(items); do \
		grep $$i Petitions.txt ;\
		make --no-print-directory \
			rate-stat.$$i | tail -$(hist) | tac ;\
		echo ;\
	done

since ?= 10 days
diff-stats:
	@git diff \
		`git log --since "$(since)" --format=%h $(data) \
		 | tail -1` \
		 $(data) \
	| egrep '[+-]i-' | sed 's/i-/ i-/' \
	| awk ' { id=$$2; score=$$4; comm=$$3 } \
		{ s[id] = score; c[id] = comm } \
		{ d[id] += ($$1 == "+" ? score : -score) } \
		END { for (x in s) print x, c[x], d[x], s[x] }' \
	| sort > .1
	@sed '/^#/ d' Petitions.txt | sort > .2
	@join .1 .2 -a 1 | sort -nr -k3 \
		| head -10 \
		| sed 's/ /\t/;s/ /\t/;s/ /\t/;s/ /\t/'
	@printf "\nvoix en $(since:days=j) :\t"
	@cat .1 | cut -d ' ' -f 3 | grep -v - | xargs | tr ' ' + | bc
	@\rm .1 .2

all-votes:
	./stats.sh 3 days | head -2 > .1
	sed "0,/`tail -1 .1 | cut -f1`/ d" $@.txt > .2
	cat .1 .2 > $@.txt

_av.pre:
	git fetch --shallow-since="4 days"
	@git config user.name _; git config user.email _@_
	@git add $(data); git commit --allow-empty -q -m _
_av.post:
	@git reset HEAD^

_all-votes: _av.pre all-votes _av.post

all-stat:
	cat $(data) \
	| cut -d ' ' -f 2 | sort | uniq -c \
	| egrep -v 'c-$$' \
	| sed 's: \(c-[1-8]\)$$:\t\1:' \
	> $@
	join -t "`printf '\t'`" -1 2 -2 1 -a 2 -o 1.1,2.2 \
		$@ commissions.txt > $@.txt
	\rm $@

all-dyn:
	git fetch --shallow-since="11 days"
	echo "id\tcomm\tdiff\tscore\ttheme" > $@.txt
	make --no-print-directory diff-stats >> $@.txt

update: all-stat _all-votes all-dyn

update: md
md:
	@curl -s https://politipet.fr/md.txt \
	| sed 's/\t/ /' > i-md.txt
