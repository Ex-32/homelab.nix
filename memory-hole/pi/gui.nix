{
  config,
  pkgs,
  lib,
  ...
}: let
  # The session lives in the standard logind user runtime dir
  # (/run/user/<uid>, kept alive by users.pi.linger); sway and wayvnc run as
  # systemd *user* services. Clients find the compositor through
  # XDG_RUNTIME_DIR + WAYLAND_DISPLAY.
  display = "wayland-gui";
  wayvnc-port = 5900;

  sway-config = pkgs.writeText "sway-headless-config" ''
    # single headless output, arbitrary virtual mode; wayvnc >=0.8 resizes the
    # output to match the VNC client on connect
    output * mode --custom 1920x1080@60Hz

    # visible cursor while interacting, auto-hidden after idle
    seat * hide_cursor 3000

    # deliberately no bar and no keybindings: everything is driven via IPC
    # (swaymsg) or VNC input
  '';

  swaymsg-cmd = "${pkgs.sway}/bin/swaymsg";
  # swaymsg only auto-discovers its IPC socket if SWAYSOCK is set; the socket
  # name embeds sway's pid, so glob it at call time.
  sway-env = ''
    export SWAYSOCK="$(ls "$XDG_RUNTIME_DIR"/sway-ipc.* 2>/dev/null | head -n1)"
  '';

  gui-tools = pkgs.symlinkJoin {
    name = "gui-tools";
    paths = [
      (pkgs.writeShellScriptBin "guishot" ''
        out="''${1:-/tmp/guishot-$(date +%s).png}"
        ${pkgs.grim}/bin/grim "$out"
        echo "$out"
      '')

      (pkgs.writeShellScriptBin "guiclick" ''
        if [ $# -lt 2 ] || [ $# -gt 3 ]; then
          echo "usage: guiclick X Y [button1|button2|button3]" >&2
          exit 2
        fi
        btn="''${3:-button1}"
        ${sway-env}
        ${swaymsg-cmd} -q "seat * cursor set $1 $2"
        ${swaymsg-cmd} -q "seat * cursor press $btn"
        sleep 0.05
        ${swaymsg-cmd} -q "seat * cursor release $btn"
      '')

      (pkgs.writeShellScriptBin "guidrag" ''
        if [ $# -ne 4 ]; then
          echo "usage: guidrag X1 Y1 X2 Y2" >&2
          exit 2
        fi
        ${sway-env}
        ${swaymsg-cmd} -q "seat * cursor set $1 $2"
        ${swaymsg-cmd} -q "seat * cursor press button1"
        ${pkgs.wlrctl}/bin/wlrctl pointer move "$(( $3 - $1 ))" "$(( $4 - $2 ))"
        sleep 0.05
        ${swaymsg-cmd} -q "seat * cursor release button1"
      '')

      (pkgs.writeShellScriptBin "guitype" ''
        ${pkgs.wtype}/bin/wtype "$@"
      '')

      (pkgs.writeShellScriptBin "guiscroll" ''
        if [ $# -lt 1 ] || [ $# -gt 2 ]; then
          echo "usage: guiscroll DY [DX]  (positive = down/right, negative = up/left)" >&2
          exit 2
        fi
        ${pkgs.wlrctl}/bin/wlrctl pointer scroll "$1" "''${2:-0}"
      '')

      (pkgs.writeShellScriptBin "guiwindows" ''
        ${sway-env}
        ${swaymsg-cmd} -t get_tree -r \
          | ${pkgs.jq}/bin/jq -r \
            '[.. | objects | select(.type? == "con")] | .[]
             | [.id, (.app_id // "-"), (.name // "-"),
                "\(.geometry.x),\(.geometry.y) \(.geometry.width)x\(.geometry.height)"]
             | @tsv'
      '')

      (pkgs.writeShellScriptBin "guifocus" ''
        if [ $# -ne 1 ]; then
          echo "usage: guifocus APP_ID_OR_TITLE_REGEX" >&2
          exit 2
        fi
        ${sway-env}
        ${swaymsg-cmd} -q "[app_id=\"$1\"] focus" \
          || ${swaymsg-cmd} -q "[title=\"$1\"] focus"
      '')

      (pkgs.writeShellScriptBin "guilaunch" ''
        if [ $# -lt 1 ]; then
          echo "usage: guilaunch CMD [ARGS...]" >&2
          exit 2
        fi
        ${pkgs.util-linux}/bin/setsid "$@" >/tmp/gui-app-last.log 2>&1 &
        echo "pid $! (log: /tmp/gui-app-last.log)"
      '')

      (pkgs.writeShellScriptBin "guirec" ''
        # guirec [output.mkv] — record the display; Ctrl-C (or kill) to stop
        out="''${1:-/tmp/guirec-$(date +%s).mkv}"
        ${pkgs.wf-recorder}/bin/wf-recorder -f "$out"
      '')
    ];
  };
in {
  services.dbus.enable = true;

  environment.variables = {
    # XDG_RUNTIME_DIR comes from the logind session itself
    WAYLAND_DISPLAY = display;
    # make chromium (and other ozone apps) run natively on wayland
    NIXOS_OZONE_WL = "1";
    XCURSOR_THEME = "Vanilla-DMZ";
  };

  environment.systemPackages =
    [gui-tools]
    ++ (with pkgs; [
      sway # swaymsg IPC client for interactive use
      chromium
      grim
      wtype
      wlrctl
      wl-clipboard
      wf-recorder
      dejavu_fonts
      noto-fonts
      noto-fonts-color-emoji
      vanilla-dmz
    ]);

  systemd.user.services.gui-sway = {
    description = "headless sway compositor for the pi GUI session";
    wantedBy = ["default.target"];
    environment = {
      WLR_BACKENDS = "headless";
      WLR_RENDERER = "pixman";
      WLR_LIBINPUT_NO_DEVICES = "1";
      XCURSOR_THEME = "Vanilla-DMZ";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sway}/bin/sway -c ${sway-config}";
      # expose the compositor socket under a stable name; sway skips
      # wayland-0 and embeds its pid in the socket name
      ExecStartPost = pkgs.writeShellScript "gui-socket-link" ''
        sock=""
        for i in $(seq 1 50); do
          sock="$(ls "$XDG_RUNTIME_DIR"/wayland-[0-9]* 2>/dev/null | head -n1)"
          [ -n "$sock" ] && break
          sleep 0.2
        done
        if [ -z "$sock" ]; then
          echo "gui-socket-link: no wayland socket appeared in \$XDG_RUNTIME_DIR" >&2
          exit 1
        fi
        ln -sf "$sock" "$XDG_RUNTIME_DIR"/${display}
      '';
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };

  systemd.user.services.gui-wayvnc = {
    description = "wayvnc websocket VNC server on the headless sway session";
    wantedBy = ["default.target"];
    after = ["gui-sway.service"];
    environment = {
      WAYLAND_DISPLAY = display;
    };
    serviceConfig = {
      Type = "simple";
      # websocket-framed VNC on loopback only; TLS terminates at the host
      # caddy tailscale vhost. A second plain-TCP listener serves native VNC
      # clients over `ssh -L 5901:localhost:5901`. wayvnc >=0.8 detaches
      # instead of dying when the compositor restarts.
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc -r ws:127.0.0.1:${toString wayvnc-port} tcp:127.0.0.1:${toString (wayvnc-port + 1)}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
