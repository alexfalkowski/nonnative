.PHONY: features

dependencies:
	bin/setup

features:
	bundle exec cucumber

analysis:
	bundle exec rubocop
