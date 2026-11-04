# frozen_string_literal: true

require "gtk4"

module Clippy
  # Plays one agent animation at a time into a Gtk::Picture.
  #
  # Frame timing is the original format's: each frame carries its own duration,
  # so this schedules one GLib timeout per frame rather than running at a fixed
  # rate. Durations in the Clippy table range from 10ms to 1200ms within a
  # single animation, and a fixed-rate loop renders those visibly wrong.
  #
  # Two pieces of the format are what make the idle animations work, and both
  # are implemented here:
  #
  # * `branching` — after this frame, jump to one of several frames chosen by
  #   weight. This is how IdleSnooze loops for as long as it likes.
  # * `exitBranch` — when asked to stop, jump here instead of continuing, so
  #   the animation plays its way out to a rest pose rather than cutting. A
  #   stop request therefore does not take effect on the current frame; it
  #   takes effect at the next frame that offers a way out.
  #
  # Exiting takes priority over branching, which is what stops a weighted loop
  # from ignoring a stop request forever.
  class Sprite
    # Played when nothing else is, and after any animation that ends without
    # landing on a rest frame.
    REST_ANIMATION = "RestPose"

    attr_reader :agent

    def initialize(agent:)
      @agent = agent
      @frames = nil
      @index = 0
      @timer = nil
      @exiting = false
      @on_done = nil
    end

    def build
      picture.tap do
        rest
      end
    end

    # Starts `name`, interrupting whatever is playing. The optional block runs
    # when the animation finishes (or is cut short by `stop`), which is how the
    # caller chains a balloon to an animation.
    #
    # An unknown name is a no-op rather than an error: animation names come
    # from menus and config, and a typo should not take the overlay down.
    def play(name, &on_done)
      agent.frames(name).then do |frames|
        if frames
          cancel_timer
          @frames = frames
          @index = 0
          @exiting = false
          @on_done = on_done
          render_and_schedule
        end
      end
    end

    # Asks the current animation to exit through its next `exitBranch`. The
    # animation keeps playing until it reaches one.
    def stop
      @exiting = true
    end

    # Drops straight to the rest pose with no exit animation. Used on teardown.
    def rest
      cancel_timer
      @frames = agent.frames(REST_ANIMATION)
      @index = 0
      @exiting = false
      @on_done = nil
      render_frame(current_frame)
    end

    def playing? = !@timer.nil?

    # Releases the pending timeout. A GLib timeout holds a reference to this
    # block, and the block touches the picture, so a timer left running past
    # window teardown fires against a destroyed widget.
    def shutdown
      cancel_timer
    end

    def picture
      @picture ||= Gtk::Picture.new.tap do |pic|
        # The window is sized to the sprite, so the picture must never
        # negotiate a smaller size or Clippy gets letterboxed inside his own
        # window.
        pic.can_shrink = false
        pic.content_fit = :fill
        pic.set_size_request(agent.display_width, agent.display_height)
        pic.halign = :center
        pic.valign = :end
      end
    end

    private

      def current_frame = @frames && @frames[@index]

      def render_and_schedule
        current_frame.then do |frame|
          if frame
            render_frame(frame)
            schedule(frame)
          else
            finish
          end
        end
      end

      def schedule(frame)
        # A zero or missing duration would spin the main loop; the format uses
        # 10ms as its floor, so clamp to that.
        @timer = GLib::Timeout.add([frame["duration"].to_i, 10].max) do
          @timer = nil
          advance
          false
        end
      end

      def advance
        next_index(current_frame).then do |nxt|
          if nxt.nil? || nxt >= @frames.size
            finish
          else
            @index = nxt
            render_and_schedule
          end
        end
      end

      # The original format's successor rule, in its original precedence.
      def next_index(frame)
        if @exiting && frame["exitBranch"]
          frame["exitBranch"]
        elsif frame["branching"]
          branch_from(frame)
        else
          @index + 1
        end
      end

      # Weights in the table are percentages out of 100; a roll that falls past
      # every branch means "carry on to the next frame", which is how a
      # weighted loop eventually leaves.
      def branch_from(frame)
        roll = rand(100)
        running = 0
        chosen = nil

        frame["branching"]["branches"].each do |branch|
          running += branch["weight"].to_i
          if chosen.nil? && roll < running
            chosen = branch["frameIndex"]
          end
        end

        chosen || @index + 1
      end

      def render_frame(frame)
        # An empty `images` is a deliberate blank frame, not a missing asset.
        frame["images"].to_a.first.then do |offset|
          picture.paintable = offset && agent.texture_at(offset)
        end
      end

      def finish
        cancel_timer
        @frames = nil
        @on_done.then do |callback|
          @on_done = nil
          rest
          callback&.call
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
  end
end
