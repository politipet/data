fetch:
	./fetch-signatures-counts.sh

update:
	git config user.name "[Bot]"
	git config user.email "actions@github.com"
	git add i-*.txt
	git commit -m "Update petitions counts" || true
	git push origin HEAD:master

since ?= 10 days
stats:
	: hits stats since $(since)
	@git log --stat --since '$(since)' \
		| egrep 'i-.*\+$$' \
		| sed 's/ | .*//' | sort | uniq -c \
		| sort -k 1nr
