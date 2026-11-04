# frozen_string_literal: true

require "gtk4"

module Clippy
  # The speech bubble: a styled label with a tail pointing down at the agent.
  #
  # The bubble body is a CSS-styled box (see Clippy::Styles) and the tail is a
  # small Cairo triangle beneath it, because GTK4 CSS has no pseudo-elements to
  # hang one on and a rotated child box would not match the border.
  #
  # The whole thing lives inside a Gtk::Revealer so the window's natural size
  # collapses back to the sprite when nothing is being said. The transition is
  # SLIDE_DOWN and not CROSSFADE deliberately: a crossfade revealer still
  # requests its child's full size while hidden, which left a 46px invisible
  # band above Clippy's head that offset him and swallowed clicks. Only the
  # slide transitions actually animate the size down to zero.
  class Balloon
    # How long a line stays up, derived from its length rather than from the
    # animation that triggered it. Tying the two together looks wrong: the
    # agent's animations branch on a weighted roll, so Greeting is 3.7s most
    # of the time and 1.0s the rest, and a sentence that vanishes after a
    # second is unreadable.
    MS_PER_CHARACTER = 55
    MIN_DWELL_MS = 2_500
    MAX_DWELL_MS = 12_000

    # Matches the bubble's CSS border, so the tail's outline lines up with it.
    TAIL_WIDTH = 18
    TAIL_HEIGHT = 11
    BORDER_RGB = [0.35, 0.33, 0.25].freeze
    FILL_RGB = [1.0, 1.0, 0.88].freeze

    def initialize
      @timer = nil
    end

    def build
      revealer.tap do |rev|
        rev.child = column

        column.tap do |col|
          col.append(bubble)
          col.append(tail)

          bubble.tap do |box|
            box.append(label)
          end
        end

        tail.tap do |area|
          area.set_draw_func { |_, cr, width, height| draw_tail(cr, width, height) }
        end
      end
    end

    # Shows `text`, then hides it again after a dwell long enough to read it.
    #
    # Replacing the text of an already-visible balloon does not re-run the
    # reveal animation, which is what makes a sequence of lines read as one
    # continuous speech rather than a flicker. Each call restarts the dwell, so
    # the last line said is the one that governs.
    #
    # `dwell:` overrides the computed time; `dwell: nil` leaves the balloon up
    # until something hides it.
    def speak(text, dwell: :auto)
      cancel_timer
      label.text = text.to_s
      revealer.reveal_child = true

      dwell_ms(text, dwell).then do |ms|
        if ms
          @timer = GLib::Timeout.add(ms) do
            @timer = nil
            hide
            false
          end
        end
      end
    end

    def hide
      cancel_timer
      revealer.reveal_child = false
    end

    # Drops the pending auto-hide. A GLib timeout outliving the window fires
    # against a destroyed widget.
    def shutdown
      cancel_timer
    end

    def visible? = revealer.reveal_child?

    def revealer
      @revealer ||= Gtk::Revealer.new.tap do |rev|
        rev.transition_type = :slide_down
        rev.transition_duration = 180
        rev.reveal_child = false
        # Pinned to the top of the overlay so the tail sits just above the
        # agent's head.
        rev.halign = :center
        rev.valign = :start
      end
    end

    def column
      @column ||= Gtk::Box.new(:vertical, 0).tap do |box|
        box.halign = :center
      end
    end

    def bubble
      @bubble ||= Gtk::Box.new(:vertical, 0).tap do |box|
        box.add_css_class("clippy-balloon")
      end
    end

    def label
      @label ||= Gtk::Label.new.tap do |lbl|
        lbl.wrap = true
        lbl.max_width_chars = 28
        lbl.justify = :center
        lbl.xalign = 0.5
      end
    end

    def tail
      @tail ||= Gtk::DrawingArea.new.tap do |area|
        area.content_width = TAIL_WIDTH
        area.content_height = TAIL_HEIGHT
        area.halign = :center
      end
    end

    private

      def dwell_ms(text, dwell)
        if dwell == :auto
          (text.to_s.length * MS_PER_CHARACTER).clamp(MIN_DWELL_MS, MAX_DWELL_MS)
        else
          dwell
        end
      end

      def cancel_timer
        @timer.then do |id|
          if id
            GLib::Source.remove(id)
            @timer = nil
          end
        end
      end

      # A downward triangle whose top edge overlaps the bubble's bottom border,
      # so the two read as one outline. Drawn as fill-then-stroke of the two
      # slanted sides only; stroking the top edge too would draw a line across
      # the bubble's interior.
      def draw_tail(cr, width, height)
        cr.set_source_rgb(*FILL_RGB)
        cr.move_to(0, 0)
        cr.line_to(width, 0)
        cr.line_to(width / 2.0, height)
        cr.close_path
        cr.fill

        cr.set_source_rgb(*BORDER_RGB)
        cr.set_line_width(1)
        cr.move_to(0.5, 0)
        cr.line_to(width / 2.0, height - 0.5)
        cr.line_to(width - 0.5, 0)
        cr.stroke
      end
  end
end
