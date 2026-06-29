class Tokentrail < Formula
  desc "Local ledger and trail-map for Claude Code spend"
  homepage "https://tokentrail.benjaminloschen.com"
  url "https://github.com/loschenbd/tokentrail/archive/refs/tags/v0.2.5.tar.gz"
  sha256 "c01f2fc398b89615cb79b0a353bc6ab44ebf7808fa2dde3c01dd1aa541d43ac3"
  license "MIT"

  # Pin node@20 so better-sqlite3's prebuilt binary is available. Newer
  # `node` (currently v26) doesn't have a matching better-sqlite3 prebuild
  # yet, forcing a multi-minute node-gyp source build that also requires
  # an up-to-date Xcode Command Line Tools install. node 20 matches the
  # CLI's engines.node and dodges both problems.
  depends_on "node@20"
  depends_on "python" => :build

  def install
    # Don't use std_npm_args — it forces --build-from-source on native modules,
    # which makes better-sqlite3 compile via node-gyp (multi-minute step).
    # Plain `npm install` lets it fetch the npm-prebuilt binary (~5s).
    system "npm", "install", "--no-audit", "--no-fund", "--include=dev"

    # The source tarball has TypeScript sources but no dist/ (gitignored).
    # package.json's bin points at dist/src/index.js, so we have to build.
    system "npm", "run", "build"

    # Drop devDeps now that the build is done — keeps libexec lean.
    system "npm", "prune", "--omit=dev"

    # Build the macOS .app launcher BEFORE staging libexec, so the
    # Makefile's relative paths resolve against the unpacked source
    # tree (not the brew prefix). sips + iconutil ship with macOS so
    # no extra build deps are needed. If something goes wrong (e.g.
    # sips missing in an unusual environment), degrade gracefully —
    # the CLI is the primary deliverable.
    begin
      system "make", "-C", "scripts/macos-app", "app"
    rescue
      opoo "Tokentrail.app build failed — CLI is installed but the " \
           "GUI launcher won't be available. `brew reinstall` to retry."
    end

    libexec.install Dir["*"]
    chmod 0755, libexec/"dist/src/index.js"
    bin.install_symlink libexec/"dist/src/index.js" => "tokentrail"
  end

  def post_install
    # Symlink the launcher into ~/Applications/ — user-writable so
    # brew (running as the user, not root) can create the link
    # without sudo. Spotlight and LaunchPad index ~/Applications/
    # alongside /Applications/, so the app is fully discoverable.
    # Users who want it in /Applications/ instead can drag it from
    # ~/Applications/ in Finder.
    app_src = libexec/"scripts/macos-app/dist/Tokentrail.app"
    return unless app_src.exist?

    apps_dir = Pathname.new(ENV.fetch("HOME")) / "Applications"
    apps_dir.mkpath
    app_dest = apps_dir / "Tokentrail.app"
    app_dest.rmtree if app_dest.exist? || app_dest.symlink?
    app_dest.make_symlink(app_src)
  end

  def caveats
    <<~EOS
      Tokentrail.app has been installed in ~/Applications/. It's
      Spotlight-searchable (Cmd-Space "Tokentrail") and appears in
      LaunchPad. Drag it to /Applications/ from Finder if you'd
      rather have it in the system Applications folder or your Dock.

      On first launch, the app prompts you to run `tokentrail init`,
      which installs the Claude Code Stop hook, the SwiftBar menubar
      widget (if SwiftBar is present), and the launchd dashboard
      daemon.

      Power users can skip the GUI and run `tokentrail init` directly.
    EOS
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tokentrail --version")
  end
end
