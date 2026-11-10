{
  config,
  lib,
  pkgs,
  ...
}: let
  # Where the tailnet traffic enters astrocontrol.
  ingressInterface = "tailscale0";

  # Host that actually serves SMB and the Synology DSM UI. Left as a name
  # rather than an address - nftables resolves it when the ruleset is loaded,
  # and the timer below re-resolves it so a changing lease is picked up.
  nas = "syn-nas.dfjk.org";

  # SMB over TCP (139, 445) / Synology DSM (5000), plus the NetBIOS
  # name and datagram services over UDP (137, 138).
  tcpPorts = [139 445 5000];
  udpPorts = [137 138];

  portSet = ports: "{ ${lib.concatMapStringsSep ", " toString ports} }";

  # `add` + `delete` + re-declare in one file keeps the reload atomic: nft
  # parses the whole ruleset before committing, so an unresolvable ${nas}
  # leaves the rules that are already installed untouched.
  ruleset = pkgs.writeText "nas-port-forward.nft" ''
    add table ip nas-forward
    delete table ip nas-forward

    table ip nas-forward {
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;

        iifname "${ingressInterface}" tcp dport ${portSet tcpPorts} dnat ip to ${nas}
        iifname "${ingressInterface}" udp dport ${portSet udpPorts} dnat ip to ${nas}
      }

      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;

        # The NAS has no route back into the tailnet, so masquerade the
        # forwarded traffic and let conntrack send the replies back out.
        iifname "${ingressInterface}" ip daddr ${nas} masquerade
      }
    }
  '';
in {
  # Forwarded packets are routed between tailscale0 and the LAN.
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  systemd.services.nas-port-forward = {
    description = "DNAT SMB and DSM traffic from ${ingressInterface} to ${nas}";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    # the hostname has to be resolvable when the ruleset is loaded
    after = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nftables}/bin/nft -f ${ruleset}";
    };
  };

  # /etc/resolv.conf is only up once the DHCP lease is in, and the NAS address
  # is baked into the rules at load time, so keep re-resolving.
  systemd.timers.nas-port-forward = {
    wantedBy = ["timers.target"];
    timerConfig = {
      Unit = "nas-port-forward.service";
      OnBootSec = "2min";
      OnUnitInactiveSec = "5min";
    };
  };
}
