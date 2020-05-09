.PHONY: features

dependencies:
	bin/setup

outdated-dependencies:
	bundle outdated --only-explicit

features: cleanup-logs
	bundle exec cucumber --profile report $(feature)

analysis:
	bundle exec rubocop
	bundle exec chutney

cleanup-analysis:
	bundle exec rubocop -a

cleanup-logs:
	rm -rf features/logs/*.log
