# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "clippy.rb"
  spec.version = Module.new.tap { |mod| Kernel.load("#{__dir__}/lib/clippy/version.rb", mod) }::Clippy::Version::VERSION
  spec.authors = ["ruby-gtk-project"]
  spec.email = ["nathanblenheimkidd@gmail.com"]

  spec.summary = "Clippy the paperclip as a GTK4 desktop overlay"
  spec.description = "The Office Assistant as a frameless, transparent, always-on-top GTK4 window: the original Clippy sprite sheet and all 43 of its animations, in Ruby."
  spec.homepage = "https://github.com/ruby-gtk-project/clippy.rb"
  spec.licenses = ["GPL-2.0-or-later"]
  spec.required_ruby_version = ">= 3.4"

  # Linux distros often package gems and securely certify them independent
  #   of the official RubyGem certification process. Allowed via ENV["SKIP_GEM_SIGNING"]
  # Hence, only enable signing if `SKIP_GEM_SIGNING` is not set in ENV.
  # See CONTRIBUTING.md
  unless ENV.include?("SKIP_GEM_SIGNING")
    user_cert = "certs/#{ENV.fetch("GEM_CERT_USER", ENV["USER"])}.pem"
    cert_file_path = File.join(__dir__, user_cert)
    cert_chain = cert_file_path.split(",")
    cert_chain.select! { |fp| File.exist?(fp) }
    if cert_file_path && cert_chain.any?
      spec.cert_chain = cert_chain
      if $PROGRAM_NAME.end_with?("gem") && ARGV[0] == "build"
        spec.signing_key = File.join(Gem.user_home, ".ssh", "gem-private_key.pem")
      end
    end
  end

  spec.metadata["homepage_uri"] = "https://clippy.rb.github.com"
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/v#{spec.version}/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/#{spec.name}/#{spec.version}"
  spec.metadata["funding_uri"] = "https://github.com/sponsors/ruby-gtk-project"
  spec.metadata["wiki_uri"] = "#{spec.homepage}/wiki"
  spec.metadata["news_uri"] = "https://www.railsbling.com/tags/#{spec.name}"
  spec.metadata["discord_uri"] = "https://discord.gg/3qme4XHNKN"
  spec.metadata["mailing_list_uri"] = "https://www.rubyforum.org/tag/clippy.rb"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec_root = __dir__
  relative_package_path = lambda do |path|
    path.delete_prefix("#{gemspec_root}/")
  end
  enumerate_package_glob = lambda do |glob|
    Dir.glob(glob, File::FNM_DOTMATCH).filter_map do |path|
      next unless File.file?(path) && ![".", ".."].include?(File.basename(path))

      relative_package_path.call(path)
    end
  end
  enumerate_package_files = lambda do |root|
    enumerate_package_glob.call(File.join(gemspec_root, root, "**", "*"))
  end
  package_metadata_files = %w[
    CHANGELOG.md
    LICENSE.md
    README.md
    sig/clippy.rbs
  ].select { |path| File.exist?(File.join(gemspec_root, path)) }

  # Specify which files are part of the released package.
  spec.files = [
    # Root package metadata
    *package_metadata_files,
    # Code / tasks / data (NOTE: exe/ is specified via spec.bindir and spec.executables below)
    *enumerate_package_files.call("lib"),
    # Executables and executable support scripts
    *enumerate_package_files.call("exe"),
    # Sprite sheet, animation table and any translations.
    *enumerate_package_glob.call(File.join(gemspec_root, "data/**/*")),
    *enumerate_package_glob.call(File.join(gemspec_root, "po/**/*"))
  ]
  spec.rdoc_options += [
    "--title",
    "#{spec.name} - #{spec.summary}",
    "--main",
    "README.md",
    "--exclude",
    "^sig/",
    "--line-numbers",
    "--inline-source",
    "--quiet"
  ]
  spec.bindir = "exe"
  # Listed files are the relative paths from bindir above.
  spec.executables = ["clippy"]
  spec.require_paths = ["lib"]

  # Development dependencies. The GTK4 bindings themselves are in the Gemfile
  # rather than here: they build C extensions against system libraries, so a
  # `gem install` of this gem should not be made to compile them.
  spec.add_development_dependency("minitest", "~> 6.1")
  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rubocop", "~> 1.92")
end
