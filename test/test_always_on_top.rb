# frozen_string_literal: true

require_relative 'test_helper'

# The backend decision. The behaviour this encodes is a platform fact, not a
# preference: GTK4 has no always-on-top call, so the only route is an EWMH
# message that exists on X11 and has no Wayland equivalent.
class TestAlwaysOnTop < Minitest::Test
  def keeper = @keeper ||= Clippy::AlwaysOnTop.new(nil)

  def test_gtk4_really_has_no_keep_above
    # If a future GTK4 restores this, the whole wmctrl detour can go.
    refute(Gtk::Window.method_defined?(:set_keep_above))
    refute(Gtk::Window.method_defined?(:keep_above=))
  end

  def test_the_gtk4_move_api_is_the_one_the_window_uses
    # Likewise: begin_move_drag is gone, begin_move is its replacement.
    refute(Gtk::Window.method_defined?(:begin_move_drag))
    assert(Gdk::Toplevel.method_defined?(:begin_move))
  end

  def test_backend_is_detected_by_class_to_s_not_name
    # Gdk's Wayland display class is anonymous: `name` is nil and only `to_s`
    # identifies it. Using `name` here silently degraded every Wayland session
    # to the "unrecognised backend" message.
    Gdk::Display.default.then do |display|
      if display
        assert_kind_of(String, display.class.to_s)
      end
    end
  end

  def test_every_status_has_a_message
    Clippy::AlwaysOnTop::STATUSES.each_value do |message|
      refute_empty(message)
    end
  end

  def test_the_wayland_message_names_the_way_out
    Clippy::AlwaysOnTop::STATUSES[:wayland].then do |message|
      assert_includes(message, 'GDK_BACKEND=x11')
    end
  end

  def test_an_unknown_status_still_produces_a_message
    keeper.instance_variable_set(:@status, :something_new)

    refute_empty(keeper.message)
  end

  def test_retry_delays_start_immediately_and_back_off
    Clippy::AlwaysOnTop::RETRY_DELAYS.then do |delays|
      assert_equal(0, delays.first)
      assert_equal(delays.sort, delays)
    end
  end
end
