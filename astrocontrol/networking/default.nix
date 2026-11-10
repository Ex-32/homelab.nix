{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  imports = [
    ./nas-port-forward.nix
    ./tailscale.nix
  ];

  networking = {
    hostName = "astrocontrol";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = lib.mkForce true;
      allowPing = true;
    };
  };
}
