# frozen_string_literal: true

require "gtk4"

module Clippy
  # The app's CSS, installed once per display.
  #
  # Two jobs. First, the window and everything structural in it must be fully
  # transparent: an overlay that paints its own background shows up as a grey
  # rectangle around the agent. GTK4 draws a window background by default, so
  # this has to override it explicitly rather than just not setting one.
  #
  # Second, the balloon's Office-yellow look.
  module Styles
    CSS = <<~CSS
      /* The overlay window itself, and every box between it and the sprite,
         must not paint. `background: none` alone leaves the colour behind. */
      window.clippy-overlay,
      window.clippy-overlay > *,
      .clippy-transparent {
        background-color: transparent;
        background-image: none;
        box-shadow: none;
      }

      .clippy-balloon {
        background-color: #fffff0;
        border: 1px solid #59543f;
        border-radius: 10px;
        padding: 9px 13px;
        color: #1a1a1a;
        font-size: 11pt;
      }

      /* Drop shadows are drawn by the compositor on the window; on a
         transparent frameless window they would ring the empty area. */
      .clippy-balloon label {
        color: #1a1a1a;
      }
    CSS

    # Installs the stylesheet on `display`, once. Called from the application's
    # startup, before any widget is realised.
    def self.install(display = Gdk::Display.default)
      display.then do |target|
        if target
          Gtk::StyleContext.add_provider_for_display(
            target,
            provider,
            Gtk::StyleProvider::PRIORITY_APPLICATION,
          )
        end
      end
    end

    def self.provider
      @provider ||= Gtk::CssProvider.new.tap do |css|
        css.load_from_string(CSS)
      end
    end
  end
end
