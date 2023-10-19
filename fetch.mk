VOTE ?= "https://petitions.assemblee-nationale.fr/initiatives?"

all-data:
	make -f fetch.mk --jobs $(all_pages:%=page.%)
	cat page.* > $@.txt
	\rm page.*

page_url = $(VOTE)&order=recent&per_page=100&
page.%:
	curl -s -H "Accept: text/html" "$(page_url)page=$*" \
	| egrep 'progress__bar__number|card__button|area_id%' \
	| sed '/progress__bar/ { s: ::g; s:.*__number">:= :; s:<.*:: }' \
	| sed '/area_id/ { s:.*=:c :; s:">.*:: }' \
	| sed '/card__button/ { s:.*/initiatives/::; s:">.*:: }' \
	| awk '\
		/c / { area = $$2 } \
		/= / { score = $$2 } \
		/i-/ { id = $$1; print id, "c-" area, score; area="" } \
	' > $@.txt

nb_pages = $(shell curl -s -H "Accept: text/html" $(VOTE) \
	| grep -A1 initiatives-count \
	| tail -1 \
	| awk '{print $$1/100 + ($$1 % 100 ? 1 : 0) }' \
)
all_pages = $(shell seq $(nb_pages))
