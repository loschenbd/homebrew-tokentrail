class Tokentrail < Formula
  desc "Local ledger and trail-map for Claude Code spend"
  homepage "https://github.com/loschenbd/tokentrail"
  url "https://github.com/loschenbd/tokentrail/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "dc8c824695efaf587dc42112d8d0e1902a8f3392285d3a51280e0b4ed8d9a76c"
  license "MIT"

  depends_on "node"
  depends_on "python" => :build

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  test do
    assert_match "tokentrail", shell_output("#{bin}/tokentrail --version")
  end
end
