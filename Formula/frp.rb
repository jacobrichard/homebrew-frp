class Frp < Formula
  desc "Fast reverse proxy to expose a local server behind a NAT or firewall"
  homepage "https://github.com/fatedier/frp"
  url "https://github.com/fatedier/frp/archive/refs/tags/v0.62.1.tar.gz"
  sha256 ""
  license "Apache-2.0"
  head "https://github.com/fatedier/frp.git", branch: "dev"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"

    ldflags = "-s -w"
    system "go", "build", *std_go_args(ldflags: ldflags, output: bin/"frps"), "-tags", "frps", "./cmd/frps"
    system "go", "build", *std_go_args(ldflags: ldflags, output: bin/"frpc"), "-tags", "frpc", "./cmd/frpc"

    (etc/"frp").install "conf/frps.toml"
    (etc/"frp").install "conf/frpc.toml"
    (etc/"frp").install "conf/frps_full_example.toml"
    (etc/"frp").install "conf/frpc_full_example.toml"

    if OS.linux?
      # frps systemd unit
      (buildpath/"frps.service").write <<~UNIT
        [Unit]
        Description=frp server
        After=network.target

        [Service]
        Type=simple
        ExecStart=#{opt_bin}/frps -c #{etc}/frp/frps.toml
        Restart=on-failure
        RestartSec=5
        LimitNOFILE=1048576

        [Install]
        WantedBy=multi-user.target
      UNIT

      # frpc systemd unit
      (buildpath/"frpc.service").write <<~UNIT
        [Unit]
        Description=frp client
        After=network.target

        [Service]
        Type=simple
        ExecStart=#{opt_bin}/frpc -c #{etc}/frp/frpc.toml
        Restart=on-failure
        RestartSec=5
        LimitNOFILE=1048576

        [Install]
        WantedBy=multi-user.target
      UNIT

      (lib/"systemd/system").install "frps.service"
      (lib/"systemd/system").install "frpc.service"
    end

    if OS.mac?
      # frps launchd plist
      (buildpath/"com.frp.frps.plist").write <<~PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.frp.frps</string>
            <key>ProgramArguments</key>
            <array>
                <string>#{opt_bin}/frps</string>
                <string>-c</string>
                <string>#{etc}/frp/frps.toml</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>#{var}/log/frps.log</string>
            <key>StandardErrorPath</key>
            <string>#{var}/log/frps.log</string>
        </dict>
        </plist>
      PLIST

      # frpc launchd plist
      (buildpath/"com.frp.frpc.plist").write <<~PLIST
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.frp.frpc</string>
            <key>ProgramArguments</key>
            <array>
                <string>#{opt_bin}/frpc</string>
                <string>-c</string>
                <string>#{etc}/frp/frpc.toml</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>#{var}/log/frpc.log</string>
            <key>StandardErrorPath</key>
            <string>#{var}/log/frpc.log</string>
        </dict>
        </plist>
      PLIST

      (prefix/"com.frp.frps.plist").install "com.frp.frps.plist"
      (prefix/"com.frp.frpc.plist").install "com.frp.frpc.plist"
    end
  end

  def caveats
    <<~EOS
      Config files are located at:
        #{etc}/frp/frps.toml
        #{etc}/frp/frpc.toml

      Full example configs are at:
        #{etc}/frp/frps_full_example.toml
        #{etc}/frp/frpc_full_example.toml

      To start the frp server (frps):
        #{service_instructions("frps")}

      To start the frp client (frpc):
        #{service_instructions("frpc")}
    EOS
  end

  def service_instructions(name)
    if OS.mac?
      <<~MSG.chomp
        sudo cp #{opt_prefix}/com.frp.#{name}.plist /Library/LaunchDaemons/
          sudo launchctl load /Library/LaunchDaemons/com.frp.#{name}.plist
          Or as a user agent:
          cp #{opt_prefix}/com.frp.#{name}.plist ~/Library/LaunchAgents/
          launchctl load ~/Library/LaunchAgents/com.frp.#{name}.plist
      MSG
    else
      <<~MSG.chomp
        sudo systemctl enable --now #{name}
      MSG
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/frps --version")
    assert_match version.to_s, shell_output("#{bin}/frpc --version")

    # Verify server starts and binds
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
