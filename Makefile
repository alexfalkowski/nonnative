.PHONY: features

dependencies:
	bin/setup

features:
	bundle exec cucumber $(feature)

analysis:
	bundle exec rubocop

cleanup-analysis:
	bundle exec rubocop -a

cleanup-logs:
	rm -rf features/logs/*.log
