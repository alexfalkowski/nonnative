.PHONY: features

dependencies:
	gem install bundler

features:
	bundle exec cucumber

analysis:
	bundle exec rubocop
