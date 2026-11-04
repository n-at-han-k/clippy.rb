# frozen_string_literal: true

# kettle-jem:freeze
# To retain chunks of comments & code during kettle-jem templating:
# Wrap custom sections with freeze markers (e.g., as above and below this comment chunk).
# kettle-jem will then preserve content between those markers across template runs.
# kettle-jem:unfreeze

source 'https://rubygems.org'

git_source(:codeberg) { |repo_name| "https://codeberg.org/#{repo_name}" }
git_source(:gitlab) { |repo_name| "https://gitlab.com/#{repo_name}" }

#### IMPORTANT #######################################################
# Gemfile is for local development ONLY; Gemfile is NOT loaded in CI #
####################################################### IMPORTANT ####

# Include dependencies from clippy.rb.gemspec
gemspec

gem "kettle-family", "~> 1.3", ">= 1.3.37"

# Local workspace dependency wiring for *_local.gemfile overrides
gem "nomono", "~> 1.1", ">= 1.1.17", require: false # ruby >= 3.2.0

# Templating and the StructuredMerge family share this modular Gemfile.
# kettle-jem needs StructuredMerge to template, and kettle-changelog needs it at
# runtime (ast-crispr-markdown-markly -> markdown-merge -> tree_haver), so the
# test, lint, and release bundles resolve the family too. While the family is
# only partially released, registry copies pin the last published version exactly
# and cannot be satisfied alongside a local lockstep version, so a partial local
# wiring fails version solving for every command in the bundle.
#
# (env-switched: STRUCTUREDMERGE_DEV=/path/to/structuredmerge/ruby/gems for local paths)
eval_gemfile "gemfiles/modular/templating.gemfile" if
  ENV.fetch("K_JEM_TEMPLATING", "false").casecmp("true").zero? ||
  ENV.fetch("STRUCTUREDMERGE_DEV", "false").casecmp("false") != 0

# Debugging
eval_gemfile "gemfiles/modular/debug.gemfile"

# Code Coverage (env-switched: KETTLE_DEV_DEV=true for local paths)
eval_gemfile "gemfiles/modular/coverage.gemfile"

# Linting
eval_gemfile "gemfiles/modular/style.gemfile"

# Documentation
eval_gemfile "gemfiles/modular/documentation.gemfile"

# Changelog release tooling (available on Ruby versions supported by kettle-changelog)
eval_gemfile "gemfiles/modular/changelog.gemfile"

# Optional
eval_gemfile "gemfiles/modular/optional.gemfile"

### Std Lib Extracted Gems
eval_gemfile "gemfiles/modular/x_std_libs.gemfile"

# See unlocked_deps appraisal for more details on irb inclusion
gem "irb", "~> 1.17" # ruby >= 2.7
# GTK4 bindings. The overlay's window, sprite rendering and gestures are all
# plain GTK4. Adwaita is declared alongside it although nothing here uses one
# of its widgets: this repo doubles as the base for Ruby GTK4/Libadwaita apps,
# and the Nix flake builds both sets of bindings either way.
#
# Building these needs gtk4's and libadwaita-1's development files on
# PKG_CONFIG_PATH; `nix develop` provides them.
gem 'gtk4', '~> 4.3'
gem 'adwaita', '~> 4.3'

group :development, :test do
  gem 'minitest', '~> 5.0'
  gem 'rake', '~> 13.0'
end

# Deprecations as a dated promise: gem_kit declares one at runtime, and
# gem_kit-release enforces it at release time — `gem kit bump`, `changelog`,
# `release`. 0.4.0 is the first version that reads a dotted gem name, which
# this gem has: it resolves clippy.rb to lib/clippy/version.rb rather than to
# lib/clippy.rb/version.rb, a directory nothing has.
gem "gem_kit"
gem "gem_kit-release", "~> 0.4", group: :development
