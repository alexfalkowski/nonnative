include bin/build/make/help.mak
include bin/build/make/ruby.mak
include bin/build/make/git.mak
include bin/build/make/claude.mak
include bin/build/make/codex.mak

.PHONY: gem-build gem-publish clean-pkg

VERSION = $(shell ruby -Ilib -e "require 'nonnative/version'; print Nonnative::VERSION")

# Build the gem into `pkg/`.
gem-build:
	@mkdir -p pkg
	@gem build nonnative.gemspec -o pkg/nonnative-$(VERSION).gem

# Remove built gems from `pkg/`, preserving the placeholder.
clean-pkg:
	@find pkg -mindepth 1 -maxdepth 1 ! -name .keep -exec rm -rf {} +

# Publish the gem to RubyGems; pass `otp=<code>` for MFA or omit to be prompted.
gem-publish: gem-build
	@gem push pkg/nonnative-$(VERSION).gem $(if $(otp),--otp $(otp))
