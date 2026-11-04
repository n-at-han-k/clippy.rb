# frozen_string_literal: true

require_relative 'test_helper'

# The overlay's construction. These build the widget tree without presenting a
# window or running a main loop, which is the only way to assert initial state:
# once the window is mapped the backend may synthesise a crossing event, and
# the close button legitimately reveals itself in response.
class TestOverlayWindow < Minitest::Test
  include AgentFixtures

  # `register` emits GApplication::startup, which GTK requires before a window
  # may be added; without it every ApplicationWindow logs a Gtk-CRITICAL.
  # The application id has to differ per test: registering exports an object
  # at a path derived from the id, and a second application with the same id
  # fails with "an object is already exported" even under :non_unique.
  def app
    @app ||= Gtk::Application.new("org.rubygtkproject.ClippyTest#{object_id}", :non_unique)
                             .tap(&:register)
  end

  def overlay
    @overlay ||= Clippy::OverlayWindow.new(application: app, agent: real_agent).tap(&:build)
  end

  def test_the_window_is_frameless_and_transparent
    refute_predicate(overlay.window, :decorated?)
    refute_predicate(overlay.window, :resizable?)
    assert_includes(overlay.window.css_classes, 'clippy-overlay')
  end

  def test_the_balloon_starts_hidden
    refute_predicate(overlay.balloon, :visible?)
  end

  def test_the_close_button_starts_hidden
    refute(overlay.close_revealer.reveal_child?)
  end

  # CROSSFADE reserves the child's full size while hidden, which left an
  # invisible band above Clippy's head that offset him and swallowed clicks.
  def test_the_balloon_revealer_collapses_when_hidden
    # The binding returns a Gtk::RevealerTransitionType, which compares equal
    # to the symbol but is not it, so assert_equal would read backwards.
    assert(overlay.balloon.revealer.transition_type == :slide_down)
    assert_equal(0, overlay.balloon.revealer.measure(:vertical, -1)[1])
  end

  def test_the_column_asks_for_exactly_the_sprite_height_while_quiet
    assert_equal(93, overlay.column.measure(:vertical, -1)[1])
  end

  def test_speaking_makes_the_column_taller_by_the_balloon
    overlay.balloon.revealer.transition_duration = 0
    overlay.balloon.speak('Hello')

    overlay.balloon.revealer.measure(:vertical, -1)[1].then do |balloon_height|
      assert_operator(balloon_height, :>, 0)
      assert_equal(93 + balloon_height, overlay.column.measure(:vertical, -1)[1])
    end
  ensure
    overlay.shutdown
  end

  def test_the_right_click_gesture_listens_to_button_three
    assert_equal(3, overlay.right_click.button)
  end

  def test_the_menu_offers_every_animation_plus_the_fixed_entries
    assert_equal(real_agent.animation_names.size, overlay.animations_menu.n_items)
    assert_equal(4, overlay.menu_model.n_items)
  end
end
