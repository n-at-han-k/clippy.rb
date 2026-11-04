# frozen_string_literal: true

require "json"
require "gtk4"

module Clippy
  # The sprite sheet and animation table for one agent, loaded from
  # `data/clippy/`.
  #
  # The format is the original Microsoft Agent one as published by clippy.js:
  # a single sheet divided into a grid of equally sized frames, plus a table of
  # named animations whose frames reference the sheet by pixel offset.
  #
  #   {
  #     "framesize": [124, 93],
  #     "animations": {
  #       "Greeting": {
  #         "frames": [
  #           { "duration": 100, "images": [[124, 0]], "sound": "15" },
  #           { "duration": 1200, "images": [[248, 0]], "exitBranch": 6 },
  #           ...
  #         ]
  #       }
  #     }
  #   }
  #
  # `images` is an array because the format allows an overlay per frame; the
  # Clippy agent never uses more than one, and a frame with an empty `images`
  # is a deliberate blank (Clippy is off-screen for that beat).
  #
  # Textures are cut from the sheet lazily and cached by offset: 1233 frames
  # share only a few hundred distinct offsets, and cutting all of them up front
  # costs about 50MB of GPU textures for animations that may never play.
  class Agent
    # Where `data/` sits relative to this file, both in the repo and in the
    # tree the Nix build copies into `$out/share/clippy/`.
    DEFAULT_ROOT = File.expand_path("../../data/clippy", __dir__)

    # Raised when the agent directory is missing or malformed, rather than
    # letting a nil sheet surface as a confusing GTK error several frames later.
    class LoadError < StandardError; end

    attr_reader :root, :scale

    # `scale` multiplies every frame. Scaling happens once per distinct frame,
    # on the pixbuf, with nearest-neighbour: these are 124x93 pixel-art cels
    # and GTK's default smooth filter turns them to mush at 2x.
    def initialize(root: DEFAULT_ROOT, scale: 1)
      @root = root
      @scale = scale
      @textures = {}
    end

    # The parsed agent table. Reading it is what validates the install.
    def data
      @data ||= load_data
    end

    # [width, height] of a single frame in sheet pixels.
    def frame_size = data.fetch("framesize")

    # Unscaled frame dimensions, as the sheet stores them.
    def frame_width = frame_size[0]
    def frame_height = frame_size[1]

    # Scaled frame dimensions, i.e. how big the widget needs to be.
    def display_width = frame_width * scale
    def display_height = frame_height * scale

    # Animation names, sorted so menus and `--list` are stable.
    def animation_names = data.fetch("animations").keys.sort

    def animation?(name) = data.fetch("animations").key?(name)

    # The frame array for `name`, or nil when there is no such animation.
    def frames(name) = data.fetch("animations")[name]&.fetch("frames")

    # The whole sheet as a pixbuf. Kept around because every frame is cut from
    # it on demand.
    def sheet
      @sheet ||= begin
        path = File.join(root, "map.png")
        unless File.exist?(path)
          raise LoadError, "no sprite sheet at #{path}"
        end

        GdkPixbuf::Pixbuf.new(file: path)
      end
    end

    # The texture for the frame at sheet offset [x, y], cached.
    #
    # Offsets outside the sheet are clamped away by returning nil: a corrupt
    # table should drop a frame, not abort the animation.
    def texture_at(offset)
      @textures.fetch(offset) do
        @textures[offset] = build_texture(offset)
      end
    end

    private

      def load_data
        path = File.join(root, "agent.json")
        unless File.exist?(path)
          raise LoadError, "no agent table at #{path}"
        end

        JSON.parse(File.read(path)).tap do |parsed|
          unless parsed["framesize"].is_a?(Array) && parsed["animations"].is_a?(Hash)
            raise LoadError, "#{path} is not an agent table (need framesize + animations)"
          end
        end
      end

      def build_texture(offset)
        x, y = offset
        fits = x >= 0 && y >= 0 &&
          (x + frame_width) <= sheet.width &&
          (y + frame_height) <= sheet.height

        if fits
          Gdk::Texture.new(
            scaled(
              sheet.subpixbuf(
                x,
                y,
                frame_width,
                frame_height,
              ),
            ),
          )
        end
      end

      def scaled(pixbuf)
        if scale == 1
          pixbuf
        else
          pixbuf.scale(display_width, display_height, :nearest)
        end
      end
  end
end
