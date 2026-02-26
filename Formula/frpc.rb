class Frpc < Formula
  desc "frp client - fast reverse proxy client"
  homepage "https://github.com/fatedier/frp"
  url "https://github.com/fatedier/frp/archive/refs/tags/v0.62.1.tar.gz"
  sha256 "d0513f1c08f7a6b31f91ddeca64ccdec43726c20d20103de5220055daa04b903"
  license "Apache-2.0"
  head "https://github.com/fatedier/frp.git", branch: "dev"

  conflicts_with "frp", because: "frp includes frpc"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"frpc"), "-tags", "frpc", "./cmd/frpc"

    (etc/"frp").install "conf/frpc.toml"
    (etc/"frp").install "conf/frpc_full_example.toml"
  end

  service do
    run [opt_bin/"frpc", "-c", etc/"frp/frpc.toml"]
    keep_alive true
    log_path var/"log/frpc.log"
    error_log_path var/"log/frpc.log"
  end

  def caveats
    <<~EOS
      Config files:
        #{etc}/frp/frpc.toml
        #{etc}/frp/frpc_full_example.toml

      To start frpc now and restart at login:
        brew services start frpc

      To stop frpc:
        brew services stop frpc
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/frpc --version")
  end
end
