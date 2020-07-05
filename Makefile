.PHONY: features

dependencies:
	bin/setup

outdated-dependencies:
	bundle outdated --only-explicit

features: clean
	bundle exec cucumber --profile report --fail-fast $(feature)

analysis:
	bundle exec rubocop
	bundle exec chutney

cleanup-analysis:
	bundle exec rubocop -a

cleanup-logs:
	rm -rf features/logs/*.log

cleanup-reports:
	rm -rf reports

cleanup-coverage:
	rm -rf coverage

clean: cleanup-logs cleanup-reports cleanup-coverage
