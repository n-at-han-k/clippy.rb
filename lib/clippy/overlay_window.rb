# frozen_string_literal: true

require "gtk4"

module Clippy
  # The floating agent: a frameless, transparent, always-on-top window holding
  # the sprite and its speech balloon.
  #
  # Layout is a Gtk::Overlay whose main child is a vertical column of
  # [balloon, sprite]. The column (not the overlay) is what stacks the balloon
  # above Clippy's head, because an overlay child is drawn *over* the main
  # child and would cover him rather than making room. The overlay earns its
  # place with the close button, which floats over the sprite's bottom-right
  # corner on hover — on a window with no title bar there is otherwise no
  # visible way to dismiss it.
  #
  # Interaction:
  #   drag          move the window (see #on_drag_begin)
  #   click         play a random animation
  #   right-click   menu of every animation, plus hide/quit
  #
  # Sizing: `resizable = false` makes the window hug the column's natural
  # size, so it is sprite-sized while quiet and grows when the balloon opens.
  class OverlayWindow
    # Clicking rather than dragging plays one of these.
    GREETINGS = %w[Greeting Wave GetAttention Congratulate Explain].freeze

    attr_reader :agent, :sprite, :balloon

    def initialize(application:, agent:)
      @application = application
      @agent = agent
      @sprite = Sprite.new(agent: agent)
      @balloon = Balloon.new
      @always_on_top = nil
    end

    def build
      window.tap do |win|
        win.child = overlay

        overlay.tap do |ovl|
          ovl.child = column
          ovl.add_overlay(close_revealer)

          column.tap do |col|
            col.append(balloon.build)
            col.append(sprite.build)
          end

          close_revealer.tap do |rev|
            rev.child = close_button
          end

          close_button.tap do |btn|
            btn.signal_connect("clicked") { @application.quit }
          end

          ovl.add_controller(hover)
          hover.tap do |motion|
            motion.signal_connect("enter") { close_revealer.reveal_child = true }
            motion.signal_connect("leave") { close_revealer.reveal_child = false }
          end
        end

        sprite.picture.tap do |pic|
          pic.add_controller(drag)
          pic.add_controller(right_click)
        end

        drag.tap do |gesture|
          gesture.signal_connect("drag-begin") { |_, x, y| on_drag_begin(x, y) }
        end

        right_click.tap do |gesture|
          gesture.signal_connect("pressed") { |_, _, x, y| open_menu(x, y) }
        end

        menu_popover.tap do |pop|
          pop.set_parent(sprite.picture)
        end
      end
    end

    # Opens the window and asks the window manager to float it. Returns the
    # AlwaysOnTop so the caller can log what was actually achieved — the
    # request succeeds or fails per session, not per build.
    def present
      window.present
      always_on_top.tap(&:apply)
    end

    def always_on_top = @always_on_top ||= AlwaysOnTop.new(window)

    # Plays `name` and, if there is a line to go with it, says it.
    #
    # The two run independently: the balloon hides on its own reading-length
    # timer rather than when the animation ends, because the animations branch
    # on a weighted roll and can finish in a third of their usual time.
    def perform(name, text: nil)
      text.then do |line|
        if line
          balloon.speak(line)
        end
      end

      sprite.play(name)
    end

    def shutdown
      sprite.shutdown
      balloon.shutdown
    end

    def window
      @window ||= Gtk::ApplicationWindow.new(@application).tap do |win|
        win.title = "Clippy"
        win.decorated = false
        win.resizable = false
        # Gravity names the point that stays put; the window grows the other
        # way. Without this the top-left is fixed, so opening the balloon —
        # which makes the window taller — pushed Clippy bodily down the screen
        # and shoved him sideways as the bubble widened past him. He sits at
        # the bottom centre of the column, so fixing the bottom centre keeps
        # him still and lets the balloon expand up and out around him.
        #
        # gtk_window_set_gravity is a GTK 4.20 addition. GTK3's gravity was
        # removed in GTK4 and this is not the same API; there is no older
        # equivalent, which is why a frameless overlay was so awkward before.
        win.gravity = :bottom
        # Transparency is CSS (see Clippy::Styles); the class is the hook.
        win.add_css_class("clippy-overlay")
      end
    end

    def overlay = @overlay ||= Gtk::Overlay.new

    def column
      @column ||= Gtk::Box.new(:vertical, 0).tap do |box|
        box.add_css_class("clippy-transparent")
        box.halign = :center
        box.valign = :end
      end
    end

    def close_revealer
      @close_revealer ||= Gtk::Revealer.new.tap do |rev|
        rev.transition_type = :crossfade
        rev.transition_duration = 120
        rev.reveal_child = false
        rev.halign = :end
        rev.valign = :end
        rev.can_target = true
      end
    end

    def close_button
      @close_button ||= Gtk::Button.new.tap do |btn|
        btn.icon_name = "window-close-symbolic"
        btn.add_css_class("circular")
        btn.tooltip_text = "Dismiss Clippy"
        btn.valign = :end
        btn.halign = :end
      end
    end

    def drag = @drag ||= Gtk::GestureDrag.new

    def right_click
      @right_click ||= Gtk::GestureClick.new.tap do |gesture|
        gesture.button = 3
      end
    end

    def hover = @hover ||= Gtk::EventControllerMotion.new

    # Positional argument only: `Gtk::PopoverMenu.new(model: menu)` raises
    # ArgumentError in ruby-gnome 4.3.9.
    def menu_popover
      @menu_popover ||= Gtk::PopoverMenu.new(menu_model).tap do |pop|
        pop.has_arrow = true
      end
    end

    def menu_model
      @menu_model ||= Gio::Menu.new.tap do |menu|
        menu.append("Say hello", "app.animate::Greeting")
        menu.append("Surprise me", "app.random")
        menu.append_submenu("All animations", animations_menu)
        menu.append("Quit Clippy", "app.quit")
      end
    end

    def animations_menu
      @animations_menu ||= Gio::Menu.new.tap do |menu|
        agent.animation_names.each do |name|
          menu.append(name, "app.animate::#{name}")
        end
      end
    end

    private

      # Hands the move to the window manager, which is the only thing that can
      # reposition a toplevel: neither X11 nor Wayland lets a client place
      # itself, and GTK4 removed `begin_move_drag` in favour of this.
      #
      # Claiming the sequence stops the click gesture from also firing, so a
      # drag does not end in Clippy launching an animation.
      def on_drag_begin(start_x, start_y)
        drag.set_state(:claimed)
        window.surface.begin_move(
          drag.current_event_device,
          drag.current_button,
          start_x,
          start_y,
          drag.current_event_time,
        )
      end

      def open_menu(x, y)
        menu_popover.tap do |pop|
          pop.pointing_to = Gdk::Rectangle.new(
            x.to_i,
            y.to_i,
            1,
            1,
          )
          pop.popup
        end
      end
  end
end
