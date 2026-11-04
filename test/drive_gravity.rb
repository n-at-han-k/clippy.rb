# frozen_string_literal: true

# Measures, on a real display, that opening the speech balloon does not move
# Clippy.
#
# This is the one thing the headless driver cannot check: it needs a window
# manager placing a real window, so it needs X11 and xwininfo. Run it as:
#
#   nix shell nixpkgs#xwininfo --command env GDK_BACKEND=x11 ruby test/drive_gravity.rb
#
# The balloon makes the window taller. Under the default top-left gravity the
# window grew downward, so Clippy slid down the screen every time he spoke and
# drifted sideways as the bubble widened past him. Gtk::Window#gravity (new in
# GTK 4.20) names the point that stays fixed, and OverlayWindow sets it to
# :bottom — so the bottom edge and the horizontal centre must not move.

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "clippy"

def geom(xid)
  out = `xwininfo -id #{xid}`
  x = out[/Absolute upper-left X:\s+(-?\d+)/, 1].to_i
  y = out[/Absolute upper-left Y:\s+(-?\d+)/, 1].to_i
  w = out[/Width:\s+(\d+)/, 1].to_i
  h = out[/Height:\s+(\d+)/, 1].to_i
  { x: x, y: y, w: w, h: h, bottom: y + h, centre: x + w / 2 }
end

app = Clippy::Application.new(startup_animation: "RestPose")
gtk = app.build
gtk.signal_connect("activate") do
  GLib::Timeout.add(1200) do
    xid = app.overlay.window.surface.xid
    before = geom(xid)
    puts "before speaking: #{before}"

    app.overlay.perform("Greeting", text: "It looks like you are writing a Ruby GTK4 application. Would you like help with that?")

    GLib::Timeout.add(1500) do
      after = geom(xid)
      puts "after speaking:  #{after}"
      puts
      puts "height:       #{before[:h]} -> #{after[:h]}   (grew #{after[:h] - before[:h]}px)"
      puts "bottom edge:  #{before[:bottom]} -> #{after[:bottom]}   (drift #{after[:bottom] - before[:bottom]}px)"
      puts "horiz centre: #{before[:centre]} -> #{after[:centre]}   (drift #{after[:centre] - before[:centre]}px)"
      puts
      ok = (after[:bottom] - before[:bottom]).abs <= 2 && (after[:centre] - before[:centre]).abs <= 2
      puts ok ? "PASS: Clippy stayed put; the balloon grew upward." : "FAIL: Clippy moved."
      @failed = !ok
      gtk.quit
      false
    end
    false
  end
end
gtk.run([])

exit(@failed ? 1 : 0)
