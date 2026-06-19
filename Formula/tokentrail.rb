class Tokentrail < Formula
  desc "Local ledger and trail-map for Claude Code spend"
  homepage "https://github.com/loschenbd/tokentrail"
  url "https://github.com/loschenbd/tokentrail/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "dc8c824695efaf587dc42112d8d0e1902a8f3392285d3a51280e0b4ed8d9a76c"
  license "MIT"

  depends_on "node"
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
