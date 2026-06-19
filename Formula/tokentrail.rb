class Tokentrail < Formula
  desc "Local ledger and trail-map for Claude Code spend"
  homepage "https://github.com/loschenbd/tokentrail"
  url "https://github.com/loschenbd/tokentrail/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "9d8f58ea96a0f911b0ce5affef910d54968d029278243868915838acf8daac8f"
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

    libexec.install Dir["*"]
    chmod 0755, libexec/"dist/src/index.js"
    bin.install_symlink libexec/"dist/src/index.js" => "tokentrail"
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tokentrail --version")
  end
end


