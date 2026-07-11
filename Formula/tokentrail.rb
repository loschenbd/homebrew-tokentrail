class Tokentrail < Formula
  desc "Local ledger and trail-map for Claude Code spend"
  homepage "https://tokentrail.benjaminloschen.com"
  url "https://github.com/loschenbd/tokentrail/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "e1031c3597ca99804a68d84d6b9a22b149ab3902f62253c10ce169c27fd9fa27"
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

    # Build the macOS .app launcher BEFORE staging libexec. The .app
    # ends up at scripts/macos-app/dist/Tokentrail.app inside the
    # source tree; `tokentrail init` later symlinks it into
    # ~/Applications/ (post_install can't write there reliably).
    begin
      system "make", "-C", "scripts/macos-app", "app"
    rescue
      opoo "Tokentrail.app build failed — CLI installed, but `tokentrail " \
           "init` won't have a launcher to install."
    end

    libexec.install Dir["*"]
    chmod 0755, libexec/"dist/src/index.js"
    bin.install_symlink libexec/"dist/src/index.js" => "tokentrail"
  end

  def caveats
    <<~EOS
      Finish setup with:

        tokentrail init

      That symlinks the SwiftBar plugin, registers the launchd dashboard
      daemon, links the Claude Code skills, installs the Stop hook in
      the current repo's .claude/settings.json, and drops a clickable
      Tokentrail.app into ~/Applications/ (Spotlight-searchable; drag
      to /Applications/ from Finder if you'd rather have it there).
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
