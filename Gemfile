# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# GTK4 bindings. The overlay's window, sprite rendering and gestures are all
# plain GTK4. Adwaita is declared alongside it although nothing here uses one
# of its widgets: this repo doubles as the base for Ruby GTK4/Libadwaita apps,
# and the Nix flake builds both sets of bindings either way.
#
# Building these needs gtk4's and libadwaita-1's development files on
# PKG_CONFIG_PATH; `nix develop` provides them.
gem "gtk4", "~> 4.3"
gem "adwaita", "~> 4.3"

group :development, :test do
  gem "minitest", "~> 6.0"
  gem "rake", "~> 13.0"
  # .rubocop.yml is self-contained — DisabledByDefault plus the local cops in
  # cops/ — so it needs rubocop itself and nothing else.
  gem "rubocop", "~> 1.92"
end

# Deprecations as a dated promise: gem_kit declares one at runtime, and
# gem_kit-release enforces it at release time — `gem kit bump`, `changelog`,
# `release`. 0.4.0 is the first version that reads a dotted gem name, which
# this gem has: it resolves clippy.rb to lib/clippy/version.rb rather than
# lib/clippy.rb/version.rb, a directory nothing has.
gem "gem_kit"
gem "gem_kit-release", "~> 0.4", group: :development
