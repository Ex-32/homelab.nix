{
  name,
  nodes,
  pkgs,
  lib,
  inputs,
  ...
}: {
  deployment.targetHost = "astrocontrol";

  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
    ../common/base.nix
    ./filesystem
    ./networking
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  hardware.enableRedistributableFirmware = true;
}
