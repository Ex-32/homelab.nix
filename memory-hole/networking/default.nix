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
    };
  };
}
