.PHONY: features

dependencies:
	bin/setup

outdated-dependencies:
	bundle outdated --only-explicit

features: cleanup-logs
	bundle exec cucumber $(feature)

analysis:
	bundle exec rubocop

cleanup-analysis:
	bundle exec rubocop -a

cleanup-logs:
	rm -rf features/logs/*.log
