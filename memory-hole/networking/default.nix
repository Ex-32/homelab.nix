{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  imports = [
    ./tailscale.nix
    ./zerotierone.nix
  ];

  networking = {
    hostName = "memory-hole";
    domain = "tail3782b9.ts.net";
    hostId = "3efb9569";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = lib.mkForce true;
      allowPing = true;

      allowedTCPPorts = [22];
      extraInputRules = ''
        # accept all trafic from the tailnet
        ip saddr 100.100.1.0/24 accept

        # drop everything else
        drop
      '';
    };
  };
}
