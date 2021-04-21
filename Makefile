.PHONY: features

dep:
	bin/setup

outdated:
	bundle outdated --only-explicit

features: clean
	bundle exec cucumber --profile report --fail-fast $(feature)

lint:
	bundle exec rubocop

fix-lint:
	bundle exec rubocop -A

clean-logs:
	rm -rf features/logs/*.log

clean-reports:
	rm -rf reports

clean-coverage:
	rm -rf coverage

clean: clean-logs clean-reports clean-coverage
