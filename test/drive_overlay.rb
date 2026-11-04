# frozen_string_literal: true

# Drives the overlay: builds it, plays animations, opens the balloon, and
# screenshots each state. Run headlessly:
#
#   env -u DISPLAY -u WAYLAND_DISPLAY ruby test/drive_overlay.rb
#
# GDK_BACKEND is deliberately NOT set here — exe/clippy asks for X11 so the
# window can float, but the driver renders offscreen and must take whatever
# backend is available.

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'clippy'
require_relative 'gtk_driver'

app = Clippy::Application.new(startup_animation: 'RestPose')

# The default 500ms interval. Do not raise it: the balloon's minimum dwell is
# 2.5s, and at 800ms per step it auto-hides before the steps that assert it is
# still up. Screenshots occasionally come back empty on a cold first run — the
# checks are what carry the signal, and they are stable.
GtkDriver.drive(app, shots: 'tmp/shots') do |d, clippy|
  d.window { clippy.overlay.window }

  d.step('disable reveal animations so geometry is deterministic') do
    # The revealers animate over 180ms driven by the frame clock, and a
    # headless frame clock does not always tick. Asserting on a size that is
    # mid-transition is flaky (observed: 215px between the 186 closed and 247
    # open). Widgets are public memoized methods precisely so a test can reach
    # in like this; the transition TYPE, which is what actually regressed
    # before, is asserted below.
    clippy.overlay.balloon.revealer.transition_duration = 0
    clippy.overlay.close_revealer.transition_duration = 0
    d.check('balloon slides rather than crossfades') do
      # CROSSFADE still reserves the child's full size while hidden, which left
      # an invisible band above Clippy's head.
      clippy.overlay.balloon.revealer.transition_type == :slide_down
    end
  end

  d.step('the overlay builds') do
    d.check('window exists') { !clippy.overlay.window.nil? }
    d.check('window is undecorated') { clippy.overlay.window.decorated? == false }
    d.check('window carries the transparency class') do
      clippy.overlay.window.css_classes.include?('clippy-overlay')
    end
    d.check('sprite shows a frame') { !clippy.overlay.sprite.picture.paintable.nil? }
    d.check('sprite is scaled 2x (248x186)') do
      clippy.overlay.sprite.picture.paintable.width == 248
    end
    d.check('balloon starts hidden') { clippy.overlay.balloon.visible? == false }
    # The close button's initial state is asserted in test_overlay_window.rb
    # instead: the offscreen backend sometimes synthesises a crossing event
    # when the window maps, so by the time a driver step runs, a legitimate
    # 'enter' may already have opened it. The enter/leave wiring is tested
    # below.
  end

  d.step('screenshot: at rest') do
    d.shot('01-rest')
  end

  # Geometry is asserted with Gtk::Widget#measure, not allocated_width/height.
  # measure() computes the natural size synchronously; an allocation only
  # catches up when the frame clock ticks, and a headless frame clock does not
  # tick reliably — asserting on allocations failed about one run in three.
  natural_height = ->(widget) { widget.measure(:vertical, -1)[1] }
  natural_width = ->(widget) { widget.measure(:horizontal, -1)[1] }

  # Screenshots get a step to themselves. Anything that dirties the layout —
  # revealing the balloon, and `measure` itself — leaves the widget needing a
  # re-layout, and snapshotting in that state returns no render node at all.
  # One tick of the main loop is enough; the driver gives each step its own.

  d.step('the window hugs the sprite while quiet') do
    d.check('no dead band above Clippy: the hidden balloon asks for no height') do
      natural_height.call(clippy.overlay.balloon.revealer).zero?
    end
    d.check('the column asks for exactly the sprite height') do
      natural_height.call(clippy.overlay.column) == 186
    end
    d.check('sprite is not squashed') do
      clippy.overlay.sprite.picture.allocated_height == 186
    end
    puts "      column natural: #{natural_width.call(clippy.overlay.column)}x" \
         "#{natural_height.call(clippy.overlay.column)}"
  end

  d.step('speaking opens the balloon') do
    clippy.overlay.perform('Greeting', text: "Hello! It looks like you're using a computer.")
    d.check('balloon is revealed') { clippy.overlay.balloon.visible? }
    d.check('balloon carries the text') do
      clippy.overlay.balloon.label.text.start_with?('Hello!')
    end
    d.check('sprite is animating') { clippy.overlay.sprite.playing? }
  end

  d.step('the balloon renders above Clippy') do
    # The reveal is a 180ms animation and the window only resizes to its new
    # natural size on the following layout pass, so the measurements below are
    # taken a step later than the speak() that caused them.
    d.check('the reveal completed') { clippy.overlay.balloon.revealer.child_revealed? }
    d.check('the balloon now asks for height') do
      natural_height.call(clippy.overlay.balloon.revealer) > 40
    end
    d.check('the column grew by the balloon, keeping the sprite whole') do
      natural_height.call(clippy.overlay.column) ==
        186 + natural_height.call(clippy.overlay.balloon.revealer)
    end
    d.check('sprite keeps its full height next to the balloon') do
      clippy.overlay.sprite.picture.allocated_height == 186
    end
    puts "      column natural: #{natural_width.call(clippy.overlay.column)}x" \
         "#{natural_height.call(clippy.overlay.column)}"
    @one_line_height = natural_height.call(clippy.overlay.balloon.revealer)
  end

  d.step('screenshot: speaking') do
    d.shot('02-speaking')
  end

  d.step('a long line wraps instead of stretching the window') do
    clippy.overlay.balloon.speak(
      'It looks like you are writing a Ruby GTK4 application. ' \
                                       'Would you like help with memoized widget methods?',
    )
  end

  d.step('the long line is laid out') do
    d.check('balloon is still up: its dwell is independent of the animation') do
      clippy.overlay.balloon.visible?
    end
    d.check('the long line wraps rather than widening past 500px') do
      natural_width.call(clippy.overlay.balloon.revealer) < 500
    end
    d.check('the long line is taller than the short one') do
      natural_height.call(clippy.overlay.balloon.revealer) > @one_line_height
    end
    puts "      balloon natural: #{natural_width.call(clippy.overlay.balloon.revealer)}x" \
         "#{natural_height.call(clippy.overlay.balloon.revealer)} " \
         "(short line was #{@one_line_height} tall)"
  end

  d.step('screenshot: the long line') do
    d.shot('03-long-line')
  end

  d.step('a short line dwells at least the minimum') do
    d.check('dwell floor is 2.5s') { Clippy::Balloon::MIN_DWELL_MS == 2_500 }
    clippy.overlay.balloon.speak('Hi', dwell: nil)
    d.check('dwell: nil keeps it up indefinitely') { clippy.overlay.balloon.visible? }
    clippy.overlay.balloon.hide
    d.check('hide closes it') { clippy.overlay.balloon.visible? == false }
  end

  d.step('every animation plays without raising') do
    agent = clippy.overlay.agent
    bad = agent.animation_names.reject do |name|
      begin
        clippy.overlay.sprite.play(name)
        true
      rescue StandardError => e
        puts "      #{name}: #{e.class}: #{e.message}"
        false
      end
    end
    d.check("all #{agent.animation_names.size} animations start") { bad.empty? }
  end

  d.step('every frame offset resolves to a texture') do
    agent = clippy.overlay.agent
    offsets = agent.animation_names.flat_map { |n| agent.frames(n) }
                   .flat_map { |f| f['images'].to_a }
    missing = offsets.uniq.reject { |o| agent.texture_at(o) }
    puts "      #{offsets.uniq.size} distinct frames across #{offsets.size} frame slots"
    d.check('no frame offset falls outside the sheet') { missing.empty? }
  end

  d.step('the menu lists every animation') do
    d.check('menu model built') { !clippy.overlay.menu_model.nil? }
    d.check('submenu has one item per animation') do
      clippy.overlay.animations_menu.n_items == clippy.overlay.agent.animation_names.size
    end
  end

  d.step('unknown animations are ignored, not fatal') do
    clippy.overlay.sprite.play('NoSuchAnimation')
    d.check('still alive') { !clippy.overlay.sprite.picture.paintable.nil? }
  end

  # The close button's hover wiring is asserted in test_overlay_window.rb
  # instead: the offscreen backend synthesises crossing events, which race an
  # emitted 'enter' and made this fail intermittently in both directions.
  # What still needs a running loop is that the button renders at all.
  d.step('the close button renders') do
    clippy.overlay.close_revealer.reveal_child = true
  end

  d.step('screenshot: the close button') do
    d.check('button has a real allocation') do
      clippy.overlay.close_button.allocated_width > 8
    end
    d.shot('04-close-button')
  end

  d.step('shutdown releases the frame and balloon timers') do
    clippy.overlay.sprite.play('IdleSnooze')
    clippy.overlay.balloon.speak('still talking')
    clippy.overlay.shutdown
    d.check('no frame timer left running') { clippy.overlay.sprite.playing? == false }
    d.check('no balloon timer left running') do
      clippy.overlay.balloon.instance_variable_get(:@timer).nil?
    end
  end
end
