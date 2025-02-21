{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  imports = [
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
