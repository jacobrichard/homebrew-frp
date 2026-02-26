class Frps < Formula
  desc "frp server - fast reverse proxy server"
  homepage "https://github.com/fatedier/frp"
  url "https://github.com/fatedier/frp/archive/refs/tags/v0.62.1.tar.gz"
  sha256 "d0513f1c08f7a6b31f91ddeca64ccdec43726c20d20103de5220055daa04b903"
  license "Apache-2.0"
  head "https://github.com/fatedier/frp.git", branch: "dev"

  conflicts_with "frp", because: "frp includes frps"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"frps"), "-tags", "frps", "./cmd/frps"

    (etc/"frp").install "conf/frps.toml"
    (etc/"frp").install "conf/frps_full_example.toml"
  end

  service do
    run [opt_bin/"frps", "-c", etc/"frp/frps.toml"]
    keep_alive true
    log_path var/"log/frps.log"
    error_log_path var/"log/frps.log"
  end

  def caveats
    <<~EOS
      Config files:
        #{etc}/frp/frps.toml
        #{etc}/frp/frps_full_example.toml

      To start frps now and restart at login:
        brew services start frps

      To stop frps:
        brew services stop frps
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/frps --version")

    port = free_port
    (testpath/"frps_test.toml").write <<~TOML
      bindPort = #{port}
    TOML

    pid = spawn bin/"frps", "-c", testpath/"frps_test.toml"
    sleep 2

    begin
      assert_match "pong", shell_output("curl -s http://127.0.0.1:#{port}/healthz 2>&1 || true")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
