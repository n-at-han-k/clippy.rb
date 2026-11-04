# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

# ruby-gnome must be required BEFORE minitest/autorun.
#
# Both register an at_exit hook, and at_exit hooks run last-in-first-out.
# ruby-gnome's hook tears down its GLib<->Ruby callback bridge, so if it is
# required second its hook runs *first* — before minitest has run a single
# test — and every signal_connect block silently stops firing. The symptom is
# baffling: signal_connect still returns a handler id, but GLib reports
# "no handlers connected to the 'activate' signal", and UI tests pass
# vacuously because their assertions never execute.
require 'gtk4'
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

require 'clippy'

# Builds throwaway agent directories, for the paths that must fail loudly
# rather than surface as a confusing GTK error several frames later.
module AgentFixtures
  def setup
    super
    @tmpdir = Dir.mktmpdir('clippy')
  end

  def teardown
    if @tmpdir && File.exist?(@tmpdir)
      FileUtils.remove_entry(@tmpdir)
    end
    super
  end

  attr_reader :tmpdir

  # The real vendored agent, which every rendering test uses.
  def real_agent(scale: 1) = Clippy::Agent.new(scale: scale)

  # An agent directory containing `contents` as agent.json and a 2x1 grid of
  # 4x4 frames as the sheet.
  def fixture_agent(contents)
    File.write(File.join(tmpdir, 'agent.json'), JSON.dump(contents))
    GdkPixbuf::Pixbuf.new(
      colorspace:      :rgb,
      has_alpha:       true,
      bits_per_sample: 8,
      width:           8,
      height:          4,
    ).tap { |pb| pb.fill!(0x00000000) }
      .save(File.join(tmpdir, 'map.png'), 'png')

    Clippy::Agent.new(root: tmpdir)
  end
end
