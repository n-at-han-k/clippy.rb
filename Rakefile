# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib" << "test"
  t.test_files = FileList["test/test_*.rb"]
  t.warning = false
end

desc "Drive the UI headlessly and write screenshots to tmp/shots"
task :drive do
  # GTK4 renders offscreen with no display server, so this needs no Xvfb —
  # but it must NOT inherit a display, or it opens real windows.
  sh "env -u DISPLAY -u WAYLAND_DISPLAY ruby test/drive_overlay.rb"
end

desc "Run RuboCop, including the custom cops in cops/"
task :rubocop do
  sh "rubocop lib exe test"
end

desc "Run the overlay"
task :run do
  sh "ruby exe/clippy"
end

task default: %i[test drive rubocop]
