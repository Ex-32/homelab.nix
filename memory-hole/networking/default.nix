{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  hostName = "memory-hole";
  domain = "tail3782b9.ts.net";
in {
  imports = [
    ./zerotierone.nix
  ];

  options = let
    inherit (lib) types;
    forwardType = types.listOf (types.submodule {
      options = {
        srcPort = lib.mkOption {
          type = types.int;
          description = "The source port on the host that will be forwarded.";
        };
        destPort = lib.mkOption {
          type = types.int;
          description = "The destination port that will be forwarded to";
        };
        destAddr = lib.mkOption {
          type = types.str;
          description = "The destination address that will be forwarded to";
        };
      };
    });
  in {
    webForward = lib.mkOption {
      type = forwardType;
      default = [];
    };

    tcpForward = lib.mkOption {
      type = forwardType;
      default = [];
    };
  };

  config = {
    networking = {
      inherit hostName domain;
      hostId = "3efb9569";
      useDHCP = lib.mkDefault true;

      firewall = {
        enable = lib.mkForce true;
        allowPing = true;

        allowedTCPPorts = let
          getSrcPort = forward: forward.srcPort;
        in
          (map getSrcPort config.tcpForward)
          ++ (map getSrcPort config.webForward);
      };

      nat = let
        tcpForwards2forwardPorts = {
          srcPort,
          destPort,
          destAddr,
        }: {
          sourcePort = srcPort;
          proto = "tcp";
          destination = "${destAddr}:${builtins.toString destPort}";
        };
      in {
        enable = true;
        internalInterfaces = ["ve-+"];
        forwardPorts = map tcpForwards2forwardPorts config.tcpForward;
      };
    };

    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        permitCertUid = "caddy";
      };

      caddy = let
        webForwards2virtualHosts = {
          srcPort,
          destPort,
          destAddr,
        }: {
          name = "${hostName}.${domain}:${builtins.toString srcPort}";
          value = {
            extraConfig = ''
              reverse_proxy ${destAddr}:${builtins.toString destPort}
            '';
          };
        };
      in {
        enable = true;
        virtualHosts =
          builtins.listToAttrs (map webForwards2virtualHosts config.webForward);
      };
    };
  };
}
