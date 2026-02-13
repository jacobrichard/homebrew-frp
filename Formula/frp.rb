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
      (buildpath/"frps.service").write <<~UNIT
        [Unit]
        Description=frp server
        After=network.target

        [Service]
        Type=simple
        ExecStart=#{opt_bin}/frps -c #{etc}/frp/frps.toml
        Restart=always
        RestartSec=5
        LimitNOFILE=1048576

        [Install]
        WantedBy=multi-user.target
      UNIT

      (buildpath/"frpc.service").write <<~UNIT
        [Unit]
        Description=frp client
        After=network.target

        [Service]
        Type=simple
        ExecStart=#{opt_bin}/frpc -c #{etc}/frp/frpc.toml
        Restart=always
        RestartSec=5
        LimitNOFILE=1048576

        [Install]
        WantedBy=multi-user.target
      UNIT

      (lib/"systemd/system").install "frps.service"
      (lib/"systemd/system").install "frpc.service"
    end

    if OS.mac?
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
            <false/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>#{var}/log/frps.log</string>
            <key>StandardErrorPath</key>
            <string>#{var}/log/frps.log</string>
        </dict>
        </plist>
      PLIST

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
            <false/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>#{var}/log/frpc.log</string>
            <key>StandardErrorPath</key>
            <string>#{var}/log/frpc.log</string>
        </dict>
        </plist>
      PLIST

      prefix.install "com.frp.frps.plist"
      prefix.install "com.frp.frpc.plist"
    end
  end

  def post_install
    (var/"log").mkpath

    if OS.mac?
      launch_agents = Pathname(Dir.home)/"Library/LaunchAgents"
      launch_agents.mkpath
      %w[frps frpc].each do |name|
        plist = prefix/"com.frp.#{name}.plist"
        target = launch_agents/"com.frp.#{name}.plist"
        target.unlink if target.exist? || target.symlink?
        target.make_symlink(plist)
      end
    end

    if OS.linux?
      systemd_dir = Pathname("/etc/systemd/system")
      %w[frps frpc].each do |name|
        unit = lib/"systemd/system/#{name}.service"
        target = systemd_dir/"#{name}.service"
        if systemd_dir.writable?
          target.unlink if target.exist? || target.symlink?
          target.make_symlink(unit)
        end
      end
    end
  end

  def post_uninstall
    if OS.mac?
      launch_agents = Pathname(Dir.home)/"Library/LaunchAgents"
      %w[frps frpc].each do |name|
        label = "com.frp.#{name}"
        plist = launch_agents/"#{label}.plist"
        system "launchctl", "bootout", "gui/#{Process.uid}/#{label}" if plist.exist?
        plist.unlink if plist.exist? || plist.symlink?
      end
    end

    if OS.linux?
      %w[frps frpc].each do |name|
        unit = Pathname("/etc/systemd/system/#{name}.service")
        unit.unlink if unit.symlink? && !unit.exist?
      end
    end
  end

  def caveats
    if OS.mac?
      <<~EOS
        Config files:
          #{etc}/frp/frps.toml
          #{etc}/frp/frpc.toml

        Full example configs:
          #{etc}/frp/frps_full_example.toml
          #{etc}/frp/frpc_full_example.toml

        LaunchAgent plists have been symlinked to ~/Library/LaunchAgents/.

        To start the frp server:
          launchctl load ~/Library/LaunchAgents/com.frp.frps.plist

        To stop the frp server:
          launchctl unload ~/Library/LaunchAgents/com.frp.frps.plist

        To start the frp client:
          launchctl load ~/Library/LaunchAgents/com.frp.frpc.plist

        To stop the frp client:
          launchctl unload ~/Library/LaunchAgents/com.frp.frpc.plist

        To run as a system-wide daemon instead (requires root):
          sudo cp #{opt_prefix}/com.frp.frps.plist /Library/LaunchDaemons/
          sudo launchctl load /Library/LaunchDaemons/com.frp.frps.plist
      EOS
    else
      <<~EOS
        Config files:
          #{etc}/frp/frps.toml
          #{etc}/frp/frpc.toml

        Full example configs:
          #{etc}/frp/frps_full_example.toml
          #{etc}/frp/frpc_full_example.toml

        Systemd unit files have been symlinked to /etc/systemd/system/.
        If the install was not run as root, you will need to link them manually:

          sudo systemctl link #{opt_lib}/systemd/system/frps.service
          sudo systemctl link #{opt_lib}/systemd/system/frpc.service

        To enable and start the frp server:
          sudo systemctl enable --now frps

        To enable and start the frp client:
          sudo systemctl enable --now frpc
      EOS
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/frps --version")
    assert_match version.to_s, shell_output("#{bin}/frpc --version")

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
