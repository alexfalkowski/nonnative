.PHONY: features

dep:
	bin/setup

# Update proto deps
proto-update-all:
	make -C test update-all

# Update all deps
dep-update-all: proto-update-all
	bundle update

# Check outdated deps
outdated:
	bundle outdated --only-explicit

# Run all the features
features: clean
	bundle exec cucumber --profile report --fail-fast $(feature)

# Lint all the code
lint:
	bundle exec rubocop

# Fix the lint issues in the code (if possible)
fix-lint:
	bundle exec rubocop -A

clean-logs:
	rm -rf features/logs/*.log

clean-reports:
	rm -rf reports

clean-coverage:
	rm -rf coverage

clean: clean-logs clean-reports clean-coverage
