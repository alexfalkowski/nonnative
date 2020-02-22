.PHONY: features

dependencies:
	bin/setup

outdated-dependencies:
	bundle outdated --only-explicit

features:
	bundle exec cucumber $(feature)

analysis:
	bundle exec rubocop

audit:
	bundle exec bundle-audit update
	bundle exec bundle-audit

cleanup-analysis:
	bundle exec rubocop -a

cleanup-logs:
	rm -rf features/logs/*.log
