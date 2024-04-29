# frozen_string_literal: true

# Taken from https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
module Nonnative
  def executable_path(name)
    [name, *ENV['PATH'].split(File::PATH_SEPARATOR).map { |p| File.join(p, name) }].find { |f| File.executable?(f) }
  end
end
