.PHONY: features

dependencies:
	gem install bundler
	bundle check --path vendor/bundle || bundle install --path vendor/bundle
	bundle clean

features:
	bundle exec cucumber

analysis:
	bundle exec rubocop
