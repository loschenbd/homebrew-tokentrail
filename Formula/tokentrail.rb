class Tokentrail < Formula
  desc "Local ledger and trail-map for Claude Code spend"
  homepage "https://tokentrail.benjaminloschen.com"
  url "https://github.com/loschenbd/tokentrail/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "ee3be2df264232b627e5c4b1b69771214ca2d74720b943c4308d6e69cc17b784"
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

    # Build the native SwiftUI menu-bar app BEFORE staging libexec. build.sh
    # emits scripts/menubar-native/dist/Tokentrail.app inside the source tree;
    # `tokentrail init` later copies it into ~/Applications/ and registers a
    # LaunchAgent (post_install can't write there reliably). Built from source
    # here, so it's ad-hoc signed with no com.apple.quarantine — Gatekeeper
    # runs it without a prompt. Guarded: if the Swift toolchain is missing the
    # CLI still installs and `tokentrail init` prints a build hint.
    begin
      system "bash", "scripts/menubar-native/build.sh"
    rescue
      opoo "Menu-bar app build failed (Swift toolchain?) — CLI installed. Run " \
           "`xcode-select --install`, then `tokentrail init` to add it."
    end

    libexec.install Dir["*"]
    chmod 0755, libexec/"dist/src/index.js"
    bin.install_symlink libexec/"dist/src/index.js" => "tokentrail"
  end

  def caveats
    <<~EOS
      Finish setup with:

        tokentrail init

      That registers the launchd dashboard daemon, links the Claude Code
      skills, installs the Stop hook in the current repo's
      .claude/settings.json, and installs the native Tokentrail menu-bar app
      into ~/Applications/ (launched via a LaunchAgent; your running total
      appears within ~60s).

      The menu-bar app is built from source during install, so it's ad-hoc
      signed and runs without a Gatekeeper prompt. If it didn't build, install
      the Swift toolchain with `xcode-select --install` and re-run
      `tokentrail init`.
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
