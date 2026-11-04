# frozen_string_literal: true

require "gtk4"

module Clippy
  # Keeps the overlay window stacked above other windows.
  #
  # There is no GTK call for this. GTK3's `gtk_window_set_keep_above` was
  # deprecated and then REMOVED in GTK4 — the method does not exist on
  # Gtk::Window at all — because stacking is a window-manager policy decision
  # and Wayland deliberately denies it to applications.
  #
  # So this asks the window manager, which only works on X11:
  #
  # * X11 (including Xwayland) — send the EWMH `_NET_WM_STATE_ABOVE` client
  #   message for our window. Mutter, KWin, and the wlroots X11 shims all
  #   honour it. `wmctrl` is used to send it because the message has to go to
  #   the root window as a real XSendEvent, and the Ruby bindings expose no way
  #   to do that. Writing the property directly with `xprop` is NOT equivalent:
  #   it bypasses the window manager, which then overwrites it on the next
  #   state change.
  #
  # * Wayland — not possible. The wlr-layer-shell protocol exists for exactly
  #   this, but GNOME's Mutter does not implement it and has rejected it, so on
  #   a GNOME Wayland session no application window can raise itself. The
  #   overlay still works, it just sits in the normal stacking order.
  #
  # `exe/clippy` therefore defaults to the X11 backend. See `status` for what
  # actually happened, which the application logs once at startup.
  class AlwaysOnTop
    # Mutter maps the window a moment after `present` returns, and the client
    # message is ignored if it arrives first. These are retry delays in ms.
    RETRY_DELAYS = [0, 250, 1000].freeze

    # What `apply` achieved, for the one startup log line.
    STATUSES = {
      applied:     "window set always-on-top via _NET_WM_STATE_ABOVE",
      no_wmctrl:   "wmctrl not found: install it for always-on-top (nix profile install nixpkgs#wmctrl)",
      wayland:     "Wayland session: always-on-top is not available to applications. " \
               "Re-run with GDK_BACKEND=x11 to float above other windows.",
      unsupported: "unrecognised display backend: not attempting always-on-top",
    }.freeze

    attr_reader :status

    def initialize(window)
      @window = window
      @status = nil
    end

    # Schedules the attempt. Safe to call before the window is mapped.
    #
    # Returns the status symbol decided from the backend alone; the X11 path
    # resolves to :applied or :no_wmctrl asynchronously, once the window has an
    # XID to name.
    def apply
      @status = backend_status
      if @status == :applied
        schedule_retries
      end
      @status
    end

    # Human-readable outcome, for logging.
    def message = STATUSES.fetch(@status, STATUSES[:unsupported])

    # The backend is identified by the display's class — GdkX11::X11Display vs
    # GdkWaylandDisplay. There is no portable accessor for it, and under some
    # offscreen/headless setups the class is anonymous and `name` is nil, which
    # is why this tolerates a blank.
    def x11? = backend_name.include?("X11")

    def wayland? = backend_name.include?("Wayland")

    # `Class#name` is nil here: the Wayland display class is created
    # dynamically by the bindings and never bound to a Ruby constant, so only
    # `to_s` reports "GdkWaylandDisplay". X11 is a real constant
    # (GdkX11::X11Display) and works either way.
    def backend_name = Gdk::Display.default.class.to_s

    private

      def backend_status
        if x11?
          if wmctrl?
            :applied
          else
            :no_wmctrl
          end
        elsif wayland?
          :wayland
        else
          :unsupported
        end
      end

      def wmctrl? = @wmctrl ||= system("command -v wmctrl > /dev/null 2>&1")

      # Re-sent a few times: the first attempt usually lands before Mutter has
      # finished mapping the window, and a dropped client message is silent.
      def schedule_retries
        RETRY_DELAYS.each do |delay|
          GLib::Timeout.add(delay) do
            raise_above
            false
          end
        end
      end

      def raise_above
        xid.then do |id|
          if id
            # -i takes the window id; the hex form is what wmctrl parses.
            system(

              "wmctrl",

              "-i",

              "-r",

              format("0x%08x", id),

              "-b",

              "add,above",
              out: File::NULL,
              err: File::NULL,
            )
          end
        end
      end

      # nil until the window is mapped, and nil forever on Wayland, where the
      # surface is a GdkWaylandToplevel with no xid method.
      def xid
        @window.surface.then do |surface|
          if surface.respond_to?(:xid)
            surface.xid
          end
        end
      end
  end
end
