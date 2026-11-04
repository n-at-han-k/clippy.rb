# frozen_string_literal: true

require "gtk4"

module Clippy
  # The application: one overlay window holding the agent.
  #
  # House style (see .claude/skills/ruby-gtk): every widget is a memoized
  # method, all configuration lives in its `tap`, assembly happens only in
  # `build`, and the launcher is one expression — `Clippy::Application.new.build.run`.
  #
  # Gtk::Application rather than Adwaita::Application: nothing here is an
  # Adwaita widget (the whole point is a window with no chrome at all), so
  # pulling in libadwaita's stylesheet would only add a theme background this
  # has to override.
  class Application
    APP_ID = "org.rubygtkproject.Clippy"

    # Shown with the animation of the same name, so clicking Clippy produces
    # something that reads as a thought rather than a silent twitch.
    TIPS = {
      "Greeting"          => "Hello! It looks like you're using a computer.",
      "Wave"              => "Over here!",
      "GetAttention"      => "Psst — are you sure about that?",
      "Congratulate"      => "Nicely done!",
      "Explain"           => "Let me explain…",
      "Thinking"          => "Hmm, let me think about that.",
      "Searching"         => "Looking that up…",
      "Writing"           => "It looks like you're writing code. Need help?",
      "Processing"        => "Working on it…",
      "Alert"             => "Careful!",
      "GoodBye"           => "See you later!",
      "Print"             => "Printing…",
      "Save"              => "Saving your work.",
      "SendMail"          => "Off it goes.",
      "GetTechy"          => "Time to get technical.",
      "GetWizardy"        => "A little magic…",
      "GetArtsy"          => "Feeling creative.",
      "CheckingSomething" => "Just checking something…",
      "EmptyTrash"        => "Taking out the rubbish.",
    }.freeze

    def initialize(agent: Agent.new(scale: 2), startup_animation: "Greeting")
      @agent = agent
      @startup_animation = startup_animation
    end

    def build
      app.tap do
        app.signal_connect("startup") do
          Styles.install
        end

        app.signal_connect("activate") do
          overlay.build
          install_actions

          overlay.present.then do |keeper|
            warn "clippy: #{keeper.message}"
          end

          greet
        end

        app.signal_connect("shutdown") do
          overlay.shutdown
        end
      end
    end

    def app = @app ||= Gtk::Application.new(APP_ID, :default_flags)

    def overlay
      @overlay ||= OverlayWindow.new(
        application: app,
        agent:       @agent,
      )
    end

    private

      # `animate` takes the animation name as its parameter, so one action
      # backs all 43 menu entries.
      def install_actions
        Gio::SimpleAction.new("animate", GLib::VariantType.new("s")).tap do |action|
          action.signal_connect("activate") { |_, parameter| perform(parameter.get_string.first) }
          app.add_action(action)
        end

        Gio::SimpleAction.new("random").tap do |action|
          action.signal_connect("activate") { perform(@agent.animation_names.sample) }
          app.add_action(action)
        end

        Gio::SimpleAction.new("quit").tap do |action|
          action.signal_connect("activate") { app.quit }
          app.add_action(action)
        end
      end

      def greet
        # The window needs a beat to map before the first animation looks
        # right; starting it in `activate` plays frames into an unmapped
        # surface and the opening of the animation is lost.
        GLib::Timeout.add(400) do
          perform(@startup_animation)
          false
        end
      end

      def perform(name)
        overlay.perform(name, text: TIPS[name])
      end
  end
end
