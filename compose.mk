-include .join.targets

%.txt:
	: generating i-$@
	$(make) $*.sum > i-$@

%.join:
	@cat $(target.items) | cut -f 1 | sort -u > .0	;\
	for x in $(target.items); do			\
		join -t "$(tab)" -a 1 .0 $$x		\
		| awk '{print $$3}' > .1+$$x		;\
	done						;\
	paste .0 $(target.items:%=.1+%)			;\
	\rm .0 .1+*

target.items = $(items:%=i-%.txt)
tab := $(shell printf "\t")

%.sum:
	$(make) $*.join \
	| awk -F "\t" '					\
		{for (n=2; n <= NF; n++)		\
			if ($$n) t[n] = $$n }		\
		{s=0; for (i in t) s+=t[i]}		\
		{print $$1 "\t" s}			\
	'

.join.targets: specs = compose.txt
.join.targets:
	@sed '	s/\s*=/.join: items=/'		$(specs) > $@
	@awk '	{print "all: " $$1 ".txt"}	\
		{print $$1 ".join:"}		\
	'					$(specs) >> $@

make := @make -f compose.mk --no-print-directory
